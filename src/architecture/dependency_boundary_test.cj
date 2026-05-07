package grammy4cj.architecture

import std.unittest.*

@Test
public class DependencyBoundaryTest {
    @TestCase
    public func boundaryRuleManifestCoversLayerOneDirections(): Unit {
        @Expect(dependencyBoundaryRuleCount(), 12)
        @Expect(coreForbiddenImports().size, 5)
        @Expect(contextForbiddenImports().size, 1)
        @Expect(platformForbiddenImports().size, 2)
        @Expect(convenienceForbiddenImports().size, 2)
    }

    @TestCase
    public func boundaryRuleManifestNamesCriticalForbiddenEdges(): Unit {
        @Expect(coreForbiddenImports()[0], "grammy4cj.bot")
        @Expect(coreForbiddenImports()[1], "grammy4cj.context")
        @Expect(contextForbiddenImports()[0], "grammy4cj.platform")
        @Expect(platformForbiddenImports()[0], "grammy4cj.bot")
        @Expect(convenienceForbiddenImports()[0], "grammy4cj.core.ApiClient")
    }
}
