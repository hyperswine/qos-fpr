/* Metal compute backend for exact, guarded FP-RISC vector operations. */
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "fpr.h"
#include <stdio.h>
#include <stdlib.h>

#define VL_B0 16

static id<MTLDevice> device;
static id<MTLCommandQueue> queue;
static id<MTLComputePipelineState> axpb_pipeline;
static id<MTLComputePipelineState> pair_sum_pipeline;
static int init_tried;

static int metal_init(void) {
  if (init_tried) return axpb_pipeline != nil;
  init_tried = 1;
  device = MTLCreateSystemDefaultDevice();
  if (!device) return 0;
  queue = [device newCommandQueue];
  NSString *source =
      @"#include <metal_stdlib>\n"
       "using namespace metal;\n"
       "kernel void axpb(device int *values [[buffer(0)]],\n"
       "                 constant int &a [[buffer(1)]],\n"
       "                 constant int &b [[buffer(2)]],\n"
       "                 constant uint &n [[buffer(3)]],\n"
       "                 uint i [[thread_position_in_grid]]) {\n"
       "  if (i < n) values[i] = a * values[i] + b;\n"
      "}\n"
      "kernel void pair_sum(const device int *left [[buffer(0)]],\n"
      "                     const device int *right [[buffer(1)]],\n"
      "                     device int *sums [[buffer(2)]],\n"
      "                     constant uint &n [[buffer(3)]],\n"
      "                     uint i [[thread_position_in_grid]]) {\n"
      "  if (i < n) sums[i] = left[i] + right[i];\n"
       "}\n";
  NSError *error = nil;
  id<MTLLibrary> library = [device newLibraryWithSource:source options:nil error:&error];
  if (!library) {
    fprintf(stderr, "[vec-gpu] Metal shader: %s\n", error.localizedDescription.UTF8String);
    return 0;
  }
  id<MTLFunction> function = [library newFunctionWithName:@"axpb"];
  axpb_pipeline = [device newComputePipelineStateWithFunction:function error:&error];
  if (!axpb_pipeline) {
    fprintf(stderr, "[vec-gpu] Metal pipeline: %s\n", error.localizedDescription.UTF8String);
    return 0;
  }
  function = [library newFunctionWithName:@"pair_sum"];
  pair_sum_pipeline = [device newComputePipelineStateWithFunction:function error:&error];
  if (!pair_sum_pipeline) {
    fprintf(stderr, "[vec-gpu] Metal pair pipeline: %s\n", error.localizedDescription.UTF8String);
    axpb_pipeline = nil;
    return 0;
  }
  fprintf(stderr, "[vec-gpu] Metal %s\n", device.name.UTF8String);
  return 1;
}

typedef struct {
  uw nblk;
  uw *blk[24];
} gpu_col_t;

int fpr_gpu_vec_fold_pair_sum(void *col0v, void *col1v, uw len, sw seed, sw *out) {
  @autoreleasepool {
    if (len < 65536 || !metal_init() || len > UINT32_MAX) return 0;
    gpu_col_t *cols[2] = {(gpu_col_t *)col0v, (gpu_col_t *)col1v};
    size_t bytes = (size_t)len * sizeof(int32_t);
    id<MTLBuffer> input[2] = {
        [device newBufferWithLength:bytes options:MTLResourceStorageModeShared],
        [device newBufferWithLength:bytes options:MTLResourceStorageModeShared]};
    id<MTLBuffer> sums = [device newBufferWithLength:bytes options:MTLResourceStorageModeShared];
    if (!input[0] || !input[1] || !sums) return 0;
    int32_t *values[2] = {input[0].contents, input[1].contents};
    for (int k = 0; k < 2; k++) {
      uw rem = len, at = 0;
      for (uw j = 0; rem; j++) {
        uw n = ((uw)VL_B0 << j) < rem ? ((uw)VL_B0 << j) : rem;
        sw *block = (sw *)cols[k]->blk[j];
        for (uw i = 0; i < n; i++) {
          if (block[i] < INT32_MIN || block[i] > INT32_MAX) return 0;
          values[k][at++] = (int32_t)block[i];
        }
        rem -= n;
      }
    }
    for (uw i = 0; i < len; i++) {
      int64_t pair = (int64_t)values[0][i] + values[1][i];
      if (pair < INT32_MIN || pair > INT32_MAX) return 0;
    }

    uint32_t count = (uint32_t)len;
    id<MTLCommandBuffer> command = [queue commandBuffer];
    id<MTLComputeCommandEncoder> encoder = [command computeCommandEncoder];
    [encoder setComputePipelineState:pair_sum_pipeline];
    [encoder setBuffer:input[0] offset:0 atIndex:0];
    [encoder setBuffer:input[1] offset:0 atIndex:1];
    [encoder setBuffer:sums offset:0 atIndex:2];
    [encoder setBytes:&count length:sizeof count atIndex:3];
    NSUInteger width = pair_sum_pipeline.threadExecutionWidth;
    [encoder dispatchThreads:MTLSizeMake(len, 1, 1)
        threadsPerThreadgroup:MTLSizeMake(width, 1, 1)];
    [encoder endEncoding];
    [command commit];
    [command waitUntilCompleted];
    if (command.status != MTLCommandBufferStatusCompleted) return 0;

    int32_t *lane_sums = sums.contents;
    uw acc = (uw)seed;
    for (uw i = 0; i < len; i++) acc += (uw)(sw)lane_sums[i];
    *out = (sw)acc;
    fprintf(stderr, "[vec-gpu] fold pair-sum Metal rows=%llu\n",
            (unsigned long long)len);
    return 1;
  }
}

int fpr_gpu_vec_axpb(uw *const *blocks, uw len, sw av, sw bv) {
  @autoreleasepool {
    if (!metal_init() || len > UINT32_MAX) return 0;
    size_t bytes = (size_t)len * sizeof(int32_t);
    id<MTLBuffer> buffer = [device newBufferWithLength:bytes options:MTLResourceStorageModeShared];
    if (!buffer) return 0;
    int32_t *values = buffer.contents;
    uw rem = len, at = 0;
    for (uw j = 0; rem; j++) {
      uw n = ((uw)VL_B0 << j) < rem ? ((uw)VL_B0 << j) : rem;
      sw *block = (sw *)blocks[j];
      for (uw i = 0; i < n; i++) values[at++] = (int32_t)block[i];
      rem -= n;
    }

    int32_t a = (int32_t)av, b = (int32_t)bv;
    uint32_t count = (uint32_t)len;
    id<MTLCommandBuffer> command = [queue commandBuffer];
    id<MTLComputeCommandEncoder> encoder = [command computeCommandEncoder];
    [encoder setComputePipelineState:axpb_pipeline];
    [encoder setBuffer:buffer offset:0 atIndex:0];
    [encoder setBytes:&a length:sizeof a atIndex:1];
    [encoder setBytes:&b length:sizeof b atIndex:2];
    [encoder setBytes:&count length:sizeof count atIndex:3];
    NSUInteger width = axpb_pipeline.threadExecutionWidth;
    [encoder dispatchThreads:MTLSizeMake(len, 1, 1)
        threadsPerThreadgroup:MTLSizeMake(width, 1, 1)];
    [encoder endEncoding];
    [command commit];
    [command waitUntilCompleted];
    if (command.status != MTLCommandBufferStatusCompleted) return 0;

    rem = len; at = 0;
    for (uw j = 0; rem; j++) {
      uw n = ((uw)VL_B0 << j) < rem ? ((uw)VL_B0 << j) : rem;
      sw *block = (sw *)blocks[j];
      for (uw i = 0; i < n; i++) block[i] = values[at++];
      rem -= n;
    }
    fprintf(stderr, "[vec-gpu] axpb Metal lanes=%llu\n", (unsigned long long)len);
    return 1;
  }
}