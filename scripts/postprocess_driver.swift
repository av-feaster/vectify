import Darwin
import Foundation

@main
enum PostprocessDriverMain {
    static func main() {
        guard CommandLine.argc == 3 else {
            fputs("usage: postprocess_driver <in.xml> <out.xml>\n", stderr)
            exit(2)
        }
        do {
            let input = URL(fileURLWithPath: CommandLine.arguments[1])
            let output = URL(fileURLWithPath: CommandLine.arguments[2])
            let data = try Data(contentsOf: input)
            let out = try VectorDrawablePostProcessor.finalizeVectorXML(data: data)
            try out.write(to: output)
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
