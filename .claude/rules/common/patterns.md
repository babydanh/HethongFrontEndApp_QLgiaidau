# Common Patterns

## Data Access

Encapsulate data access behind one interface per module (findAll, findById, create, update, delete). Business logic depends on that interface, not on the storage details. Follow the module layout that already exists; do not add a new layer without a concrete need.

## API Response Envelope

Use the envelope the repo already has. Backend: `TransformInterceptor` wraps responses as `{ statusCode, message, data }`, with `meta` for pagination. Do not hand-build a different shape.

## Reuse First

Before writing a utility, search the repo for an existing one (`grep` for the name, or `find` for the behaviour). Extract shared logic only when the repetition is real.
