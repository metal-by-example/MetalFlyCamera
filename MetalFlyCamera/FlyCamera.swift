
import Foundation

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

extension matrix_float3x3 {
    static func rotation(about axis: float3, by angle: Float) -> matrix_float3x3 {
        let c = cos(angle)
        let s = sin(angle)
        let x = float3(c + (1.0 - c) * axis.x * axis.x,
                       (1.0 - c) * axis.x * axis.y + s * axis.z,
                       (1.0 - c) * axis.x * axis.z - s * axis.y)
        let y = float3((1.0 - c) * axis.x * axis.y - s * axis.z,
                       c + (1.0 - c) * axis.y * axis.y,
                       (1.0 - c) * axis.y * axis.z + s * axis.x)
        let z = float3((1.0 - c) * axis.x * axis.z + s * axis.y,
                       (1.0 - c) * axis.y * axis.z - s * axis.x,
                       c + (1.0 - c) * axis.z * axis.z)
        
        return matrix_float3x3(x, y, z)
    }
}

class FlyCamera {
    
    let up = float3(0, 1, 0)
    var eyeSpeed: Float = 6
    var radiansPerCursorPoint: Float = 0.017
    var maximumPitchRadians: Float = (.pi / 2.0) * 0.98

    private var eye = float3(0, 0, 8)
    private var look = float3(0, 0, -1)
    
    var viewMatrix: matrix_float4x4 {
        var u = up
        var f = look
        let s = normalize(cross(f, u))
        u = normalize(cross(s, f))
        f = -f
        let t = float3(dot(s, -eye), dot(u, -eye), dot(f, -eye))
        let view = matrix_float4x4(SIMD4<Float>(s.x, u.x, f.x, 0),
                                   SIMD4<Float>(s.y, u.y, f.y, 0),
                                   SIMD4<Float>(s.z, u.z, f.z, 0),
                                   SIMD4<Float>(t.x, t.y, t.z, 1.0))
        return view
    }

    func update(timestep: Float,
                mouseDelta: float2,
                forwardPressed: Bool,
                leftPressed: Bool,
                backwardPressed: Bool,
                rightPressed: Bool)
    {
        let across = normalize(cross(look, up))
        let forward = look
        
        let xMovement: Float = (leftPressed ? -1.0 : 0.0) + (rightPressed ? 1.0 : 0.0)
        let zMovement: Float = (backwardPressed ? -1.0 : 0.0) + (forwardPressed ? 1.0 : 0.0)
        
        let movementMagnitude = hypot(xMovement, zMovement)
        if movementMagnitude > 1e-4 {
            let xzMovement = float3(xMovement * across.x + zMovement * forward.x,
                                    xMovement * across.y + zMovement * forward.y,
                                    xMovement * across.z + zMovement * forward.z)
            eye += normalize(xzMovement) * eyeSpeed * timestep
        }
        
        if mouseDelta.x != 0 {
            let yaw = -mouseDelta.x * radiansPerCursorPoint
            let yawRotation = matrix_float3x3.rotation(about: up, by: yaw)
            look = normalize(yawRotation * look)
        }
        
        if mouseDelta.y != 0 {
            let angleToUp: Float = acos(dot(look, up))
            let angleToDown: Float = acos(dot(look, -up))
            let maxPitch = max(0.0, angleToUp - (.pi / 2 - maximumPitchRadians))
            let minPitch = max(0.0, angleToDown - (.pi / 2 - maximumPitchRadians))
            var pitch = mouseDelta.y * radiansPerCursorPoint
            pitch = max(-minPitch, min(pitch, maxPitch))
            let pitchRotation = matrix_float3x3.rotation(about: across, by: pitch)
            look = normalize(pitchRotation * look)
        }
    }
}
