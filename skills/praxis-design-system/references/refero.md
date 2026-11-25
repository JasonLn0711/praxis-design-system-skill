# Refero research

Praxis includes the official Refero skill as the preferred research method for external visual references. The offline workflow is available through the local [official skill](.upstream/refero_skill/skills/refero-design/SKILL.md), [craft references](.upstream/refero_skill/skills/refero-design/references/craft-details.md), and [MCP tool guide](.upstream/refero_skill/skills/refero-design/references/mcp-tools.md). An existing connected official provider can supply live evidence. Use only task-relevant public search terms and links when calling an external service.

| Candidate | Observed capability and tradeoff | Praxis decision |
| --- | --- | --- |
| [Refero official](https://github.com/referodesign/refero_skill) | MIT skill and craft references, plus first-party tools for styles, individual screens and multistep flows. The remote service uses Refero OAuth and its live research requires a paid plan per upstream. | Bundle the complete source, use the offline method and prefer the official connection if available. Follow the [official setup guide](https://doc.refero.design/mcp/getting-started) when the user chooses to enable live search. |
| [ClementWalter/refero-cli](https://github.com/ClementWalter/refero-cli) | The supplied URL now redirects to `refero-cli`. A Python/uv CLI pulls DESIGN.md, Tailwind CSS, plain CSS, raw tokens and metadata. The inspected tree has no license file or redistribution grant. | Keep as an external link for an explicit token-export need. Bundling it would require clear redistribution permission. |
| [DarCas/refero-design-mcp](https://github.com/DarCas/refero-design-mcp) | MIT MCP centered on the public styles catalog; search and extract normalized tokens and design rules, with local Node runtime, cache and optional HTTP service. It overlaps the official style workflow and serves a narrower reference layer. | Keep as a documented alternative if a project specifically needs a local MCP and parsed style-only data. Use the official method for the broader workflow and avoid a second default service. |

## Use the evidence

The official live provider supplies the broadest research coverage here. For disconnected work, search the ten local craft guides with `catalog.py -c refero` and inspect a record such as `--show refero/typography`. Cite the bundled guide as craft evidence. Record a real screen or flow as observed only after retrieving or viewing it. For DarCas results, inspect its reported search coverage because its local style index grows on demand.

1. Use styles for a visual thesis and its composition, typography and material. Use screens for specific UI controls or states, and flows for multistep behavior. The official style catalog is primarily web marketing/product reference material. Check whether a real in-app or native screen is more relevant.
2. Inspect the details of promising results rather than selecting from previews alone. Record the link, observed trait, how it informs the project, and which parts depend on the reference's context.
3. Hold one dominant direction. Where assets or tokens are associated with a specific site, confirm separate permissions and translate any applicable principles into the project's own system.
4. If live tools are absent, signed out or fail, use existing project screens or user-provided material, the bundled craft references, and public sources available for the task. Identify the evidence you actually inspected.
