# TypeScript

`strict: true`, plus `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`. Extend
`dev-kit/tsconfig/node` or `.../web` rather than restating them.

**No `any` in hand-written code.** The one accepted occurrence is the `Kysely<any>` signature
Kysely's migration API requires; a migration is the only place it appears.

**Module resolution differs by workspace, and the difference is load-bearing.** A `NodeNext`
workspace carries a `.js` extension on every relative import, even in a `.ts` file:

    import { localDate } from '../shared/nights.js'

A bundler workspace does not. Copying an import between the two is the most common way to
break a build that type-checked a moment earlier.

**The TypeBox package is `typebox`, not `@sinclair/typebox`,** paired with
`@fastify/type-provider-typebox`. The two publish similar APIs under different names, and
installing the wrong one produces type errors that read as though the schema is at fault.
