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
  fprintf(stderr, "[vec-gpu] Metal %s\n", device.name.UTF8String);
  return 1;
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