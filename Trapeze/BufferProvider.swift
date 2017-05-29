//
//  BufferProvider.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 29.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

import Foundation
import Metal

class BufferProvider: NSObject {

  let inflightBuffersCount: Int

  private var uniformsBuffers: [MTLBuffer]
  private var avaliableBufferIndex: Int = 0

  init(device: MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {

    self.inflightBuffersCount = inflightBuffersCount
    uniformsBuffers = [MTLBuffer]()

    for _ in 0...inflightBuffersCount-1 {
      let uniformsBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: [])
      uniformsBuffers.append(uniformsBuffer)
    }
  }

  func nextUniformsBuffer(projectionMatrix: Matrix4, modelViewMatrix: Matrix4) -> MTLBuffer {

    let buffer = uniformsBuffers[avaliableBufferIndex]

    let bufferPointer = buffer.contents()

    let bufferLength = MemoryLayout<Float>.size * Matrix4.numberOfElements()

    memcpy(bufferPointer, modelViewMatrix.raw(), bufferLength)
    memcpy(bufferPointer + bufferLength, projectionMatrix.raw(), bufferLength)

    avaliableBufferIndex += 1
    if avaliableBufferIndex == inflightBuffersCount{
      avaliableBufferIndex = 0
    }
    
    return buffer
  }
}
