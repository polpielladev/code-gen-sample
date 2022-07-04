import Foundation

protocol FindThis: Decodable, Equatable {}

struct FeatureABlock: FindThis {
    let featureA: FeatureA
    
    struct FeatureA: FindThis {
        let url: URL
    }
}

enum Root {
    struct RootBlock: FindThis {
        let url: URL
        let areAllFeaturesEnabled: Bool
    }
}


struct FeatureBBlock: FindThis {
    let featureB: FeatureB
    
    struct FeatureB: FindThis {
        let url: URL
    }
}
