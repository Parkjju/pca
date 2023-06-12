//
//  matrix.swift
//  pca
//
//  Created by Jun on 2023/06/07.
//

import Foundation
import Accelerate

typealias Matrix = Array<[Double]>

// Matrix Calculation

func matAdd(mat1:Matrix, mat2:Matrix) -> Matrix {
    var outputMatrix:Matrix = []
    for i in 0..<mat1.count {
        let vec1 = mat1[i]
        let vec2 = mat2[i]
        outputMatrix.append(vecAdd(vec1: vec1, vec2: vec2))
    }
    return outputMatrix
}

func matSub(mat1:Matrix, mat2:Matrix) -> Matrix {
    var outputMatrix:Matrix = []
    for i in 0..<mat1.count {
        let vec1 = mat1[i]
        let vec2 = mat2[i]
        outputMatrix.append(vecSub(vec1: vec1, vec2: vec2))
    }
    return outputMatrix
}

func matScale(mat:Matrix, num:Double) -> Matrix {
    let outputMatrix = mat.map({vecScale(vec: $0, num: num)})
    return outputMatrix
}

func transpose(inputMatrix: Matrix) -> Matrix {
    let m = inputMatrix[0].count
    let n = inputMatrix.count
    let t = inputMatrix.reduce([], {$0+$1})
    var result = Vector(repeating: 0.0, count: m*n)
    vDSP_mtransD(t, 1, &result, 1, vDSP_Length(m), vDSP_Length(n))
    var outputMatrix:Matrix = []
    for i in 0..<m {
        outputMatrix.append(Array(result[i*n..<i*n+n]))
    }
    return outputMatrix
}

func matMul(mat1:Matrix, mat2:Matrix) -> Matrix {
    if mat1.count != mat2[0].count {
        print("error")
        return []
    }
    let m = mat1[0].count
    let n = mat2.count
    let p = mat1.count
    var mulresult = Vector(repeating: 0.0, count: m*n)
    let mat1t = transpose(inputMatrix: mat1)
    let mat1vec = mat1t.reduce([], {$0+$1})
    let mat2t = transpose(inputMatrix: mat2)
    let mat2vec = mat2t.reduce([], {$0+$1})
    vDSP_mmulD(mat1vec, 1, mat2vec, 1, &mulresult, 1, vDSP_Length(m), vDSP_Length(n), vDSP_Length(p))
    var outputMatrix:Matrix = []
    for i in 0..<m {
        outputMatrix.append(Array(mulresult[i*n..<i*n+n]))
    }
    return transpose(inputMatrix: outputMatrix)
}

// Covariance Matrix
func covarianceMatrix(inputMatrix:Matrix) -> Matrix {
    let t = transpose(inputMatrix: inputMatrix)
    return matMul(mat1: inputMatrix, mat2: t)
}

func svd(inputMatrix:Matrix) -> (u:Matrix, s:Matrix, v:Matrix) {
    // MARK: 열의 수
    let m = inputMatrix[0].count
    
    // MARK: 행의 수
    let n = inputMatrix.count
    
    // MARK: 입력 행렬을 1차원으로 변환
    let x = inputMatrix.reduce([], {$0+$1})
    
    // MARK: 특이값 행렬 계산 옵션
    var JOBZ = Int8(UnicodeScalar("A").value)
    var JOBU = Int8(UnicodeScalar("A").value)
    var JOBVT = Int8(UnicodeScalar("A").value)
    
    // MARK: 행렬 크기 변수
    var M = __CLPK_integer(m)
    var N = __CLPK_integer(n)
    
    // MARK: SVD 행렬에 사용될 1차원 변환행렬
    var A = x
    var LDA = __CLPK_integer(m)
    var S = [__CLPK_doublereal](repeating: 0.0, count: min(m,n))
    var U = [__CLPK_doublereal](repeating: 0.0, count: m*m)
    var LDU = __CLPK_integer(m)
    var VT = [__CLPK_doublereal](repeating: 0.0, count: n*n)
    var LDVT = __CLPK_integer(n)
    let lwork = min(m,n)*(6+4*min(m,n))+max(m,n)
    var WORK = [__CLPK_doublereal](repeating: 0.0, count: lwork)
    var LWORK = __CLPK_integer(lwork)
    var IWORK = [__CLPK_integer](repeating: 0, count: 8*min(m,n))
    var INFO = __CLPK_integer(0)
    if m >= n {
        dgesdd_(&JOBZ, &M, &N, &A, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &IWORK, &INFO)
    } else {
        dgesvd_(&JOBU, &JOBVT, &M, &N, &A, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &INFO)
    }
    var s = [Double](repeating: 0.0, count: m*n)
    for ni in 0...(min(m,n)-1) {
        s[ni*m+ni] = S[ni]
    }
    var v = [Double](repeating: 0.0, count: n*n)
    vDSP_mtransD(VT, 1, &v, 1, vDSP_Length(n), vDSP_Length(n))
    
    var outputU:Matrix = []
    var outputS:Matrix = []
    var outputV:Matrix = []
    for i in 0..<m {
        outputU.append(Array(U[i*m..<i*m+m]))
    }
    for i in 0..<n {
        outputS.append(Array(s[i*m..<i*m+m]))
    }
    for i in 0..<n {
        outputV.append(Array(v[i*n..<i*n+n]))
    }
    
    return (outputU, outputS, outputV)
}
