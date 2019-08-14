//
//  VectorExtensions.swift
//  ARCarstom
//
//  Created by Максим Матусевич on 8/14/19.
//  Copyright © 2019 Максим Матусевич. All rights reserved.
//

import SceneKit

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
}
