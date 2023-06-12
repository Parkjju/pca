//
//  ViewController.swift
//  pca
//
//  Created by Jun on 2023/05/31.
//

import UIKit
import CoreML
import Vision
import Accelerate

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageView2: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: 1. 랜덤으로 이미지 생성
        
        // MARK: 2. 이미지를 rgba 매트릭스로 바꾸기
        let randomImage = getRandomImage()
        let pixels = getPixels(randomImage)
        let pixelsToMatrix = pixels.map { pixel in
            pixel.toArray()
        }
        
        let svd = svd(inputMatrix: pixelsToMatrix)
        
        // MARK: SVD (svd.u) * transpose(svd.u) -> identity matrix
        // MARK: svd.s - 특이값 행렬
        // MARK: svd.u - U행렬
        // MARK: svd.v - V행렬
        
        let u0Column = svd.u.map { arr in
            arr[0]
        }
        
        let v0Column = svd.v.map { arr in
            arr[0]
        }
        
        let u1Column = svd.u.map { arr in
            arr[1]
        }
        
        let v1Column = svd.v.map { arr in
            arr[1]
        }
        
        
        
        let newPixelsWithSVD0 = matMul(mat1: [u0Column], mat2: transpose(inputMatrix: [v0Column]))
        let newPixelsWithSVD1 = matMul(mat1: [u1Column], mat2: transpose(inputMatrix: [v1Column]))
        let scaledMatrix0 = matScale(mat: newPixelsWithSVD0, num: svd.s[0][0])
        let scaledMatrix1 = matScale(mat: newPixelsWithSVD1, num: svd.s[1][1])
        
        let addMatrix = matAdd(mat1: scaledMatrix0, mat2: scaledMatrix1)
        
        var matrixToPixel: [PixelData] = []
        
        scaledMatrix0.forEach { arr in
            let a = 255
            let r = arr[0] > 255 ? 255 : arr[0] < 0 ? 0 : arr[0]
            let g = arr[1] > 255 ? 255 : arr[1] < 0 ? 0 : arr[1]
            let b = arr[2] > 255 ? 255 : arr[2] < 0 ? 0 : arr[2]
            matrixToPixel.append(PixelData(a: UInt8(a), r: UInt8(r), g: UInt8(g), b: UInt8(b)))
        }
        
        let newImage = UIImage(pixels: matrixToPixel, width: 50, height: 50)
        
        
        imageView.image = randomImage
        imageView2.image = newImage
    }
    
    func getRandomImage() -> UIImage{
        let height = 50
        let width = 50
        
        
        var pixels: [PixelData] = .init(repeating: .init(a: 0, r: 0, g: 0, b: 0), count: width * height)
        for index in pixels.indices {
            pixels[index].a = 255
            pixels[index].r = 0
            pixels[index].g = 0
            pixels[index].b = 0
        }
        
        for i in 1000..<1050{
            pixels[i].r = 200
            pixels[i].g = 200
            pixels[i].b = 200
        }
        let image = UIImage(pixels: pixels, width: width, height: height)
        return image!
    }
    
    func getPixels(_ image: UIImage) -> [PixelData]{
        var pixels: [PixelData] = []
        
        var point = 0
        
        for x in 0..<image.cgImage!.width{
            for y in 0..<image.cgImage!.height{
                
                switch(point){
                case 0:
                    print("processing.")
                    point += 1
                case 1:
                    print("processing..")
                    point += 1
                case 2:
                    print("processing...")
                    point = 0
                default:
                    break
                }
                
                pixels.append(image.pixelColor(x: x, y: y)!)
            }
        }
        
        return pixels
    }

}

