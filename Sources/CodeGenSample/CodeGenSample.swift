protocol FindThis {}

enum NamespaceOne {
    struct FindThisImpl: FindThis {
        
    }
}

struct FindAnother: FindThis {
    struct SomeOtherWrapped: FindThis {
        struct SomeOtherOtherWrapped: FindThis {
            
        }
    }
}

enum NamespaceTwo {
    struct FindAnotherOther: FindThis {
        
    }
}
