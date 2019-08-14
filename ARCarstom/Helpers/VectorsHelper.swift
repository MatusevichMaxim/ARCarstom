//
//  VectorsHelper.swift
//  ARCarstom
//
//  Created by Максим Матусевич on 8/14/19.
//  Copyright © 2019 Максим Матусевич. All rights reserved.
//

import SceneKit

func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z)
}
