/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import MetalKit
import simd

protocol MetalViewControllerDelegate: class {
  func updateLogic(timeSinceLastUpdate: CFTimeInterval)
  func renderObjects(drawable: CAMetalDrawable)
}

class MetalViewController: UIViewController {

  var device: MTLDevice!
  var metalLayer: CAMetalLayer!
  var pipelineState: MTLRenderPipelineState!
  var commandQueue: MTLCommandQueue!
  var timer: CADisplayLink!
  var projectionMatrix: float4x4!
  var lastFrameTimestamp: CFTimeInterval = 0.0
  var textureLoader: MTKTextureLoader! = nil

  weak var metalViewControllerDelegate: MetalViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    device = MTLCreateSystemDefaultDevice()
    textureLoader = MTKTextureLoader(device: device)
    
    projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)

    metalLayer = CAMetalLayer()
    metalLayer.device = device
    metalLayer.pixelFormat = .bgra8Unorm
    metalLayer.framebufferOnly = true
    view.layer.addSublayer(metalLayer)

    let defaultLibrary = device.newDefaultLibrary()!
    let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")

    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

    pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

    commandQueue = device.makeCommandQueue()

    timer = CADisplayLink(target: self, selector: #selector(MetalViewController.newFrame(displayLink:)))
    timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
  }


  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if let window = view.window {
      let scale = window.screen.nativeScale
      let layerSize = view.bounds.size

      view.contentScaleFactor = scale
      metalLayer.frame = CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height)
      metalLayer.drawableSize = CGSize(width: layerSize.width * scale, height: layerSize.height * scale)

      projectionMatrix =
        float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0),
                                         aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height),
                                         nearZ: 0.01, farZ: 100.0)
    }
  }

  func render() {
    guard let drawable = metalLayer?.nextDrawable() else { return }
    self.metalViewControllerDelegate?.renderObjects(drawable: drawable)
  }

  func newFrame(displayLink: CADisplayLink){

    if lastFrameTimestamp == 0.0
    {
      lastFrameTimestamp = displayLink.timestamp
    }

    let elapsed: CFTimeInterval = displayLink.timestamp - lastFrameTimestamp
    lastFrameTimestamp = displayLink.timestamp

    gameloop(timeSinceLastUpdate: elapsed)
  }

  func gameloop(timeSinceLastUpdate: CFTimeInterval) {

    self.metalViewControllerDelegate?.updateLogic(timeSinceLastUpdate: timeSinceLastUpdate)

    autoreleasepool {
      self.render()
    }
  }

}

