import Foundation

// swiftlint:disable all
import PathKit

// MARK: - Path extras.

// Selected by which C library module is actually available rather than by
// the platform: a musl target is Linux too, and there the module is `Musl`,
// not `Glibc`.
#if canImport(Darwin)
    import Darwin
#elseif canImport(Musl)
    import Musl
#else
    import Glibc
#endif

func systemGlob(_ pattern: UnsafePointer<CChar>!, _ flags: Int32, _ errfunc: (@convention(c) (UnsafePointer<CChar>?, Int32) -> Int32)!, _ vector_ptr: UnsafeMutablePointer<glob_t>!) -> Int32 {
    #if canImport(Darwin)
        return Darwin.glob(pattern, flags, errfunc, vector_ptr)
    #elseif canImport(Musl)
        return Musl.glob(pattern, flags, errfunc, vector_ptr)
    #else
        return Glibc.glob(pattern, flags, errfunc, vector_ptr)
    #endif
}

extension Path {
    /// Creates a directory
    ///
    /// - Throws: an errof if the directory cannot be created.
    func mkpath(withIntermediateDirectories: Bool) throws {
        try FileManager.default.createDirectory(atPath: string, withIntermediateDirectories: withIntermediateDirectories, attributes: nil)
    }

    /// Finds files and directories using the given glob pattern.
    ///
    /// - Parameter pattern: glob pattern.
    /// - Returns: found directories and files.
    func glob(_ pattern: String) -> [Path] {
        var gt = glob_t()
        guard let cPattern = strdup((self + pattern).string) else {
            fatalError("strdup returned null: Likely out of memory")
        }
        defer {
            globfree(&gt)
            free(cPattern)
        }

        // GLOB_BRACE is a GNU extension that musl does not implement, so brace
        // expansion is unavailable there; the rest of the pattern still globs.
        #if canImport(Musl)
            let flags = GLOB_TILDE | GLOB_MARK
        #else
            let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        #endif
        if systemGlob(cPattern, flags, nil, &gt) == 0 {
            #if canImport(Darwin)
                let matchc = gt.gl_matchc
            #else
                let matchc = gt.gl_pathc
            #endif
            return (0 ..< Int(matchc)).compactMap { index in
                if let path = String(validatingCString: gt.gl_pathv[index]!) {
                    return Path(path)
                }
                return nil
            }
        }
        return []
    }

    func relative(to path: Path) -> Path {
        let pathComponents = absolute().components
        let baseComponents = path.absolute().components

        var commonComponents = 0
        for (index, component) in baseComponents.enumerated() {
            if component != pathComponents[index] {
                break
            }
            commonComponents += 1
        }

        var resultComponents = Array(repeating: "..", count: baseComponents.count - commonComponents)
        resultComponents.append(contentsOf: pathComponents[commonComponents...])

        return Path(components: resultComponents)
    }
}

// swiftlint:enable all
