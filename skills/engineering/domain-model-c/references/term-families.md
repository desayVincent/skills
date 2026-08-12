# Term families (C/C++ / SDK)

Load when sharpening language and the main skill table is not enough.

Pick terms that fit the product; define only those you use.

| Prefer in CONTEXT | Mechanism noise to replace |
|-------------------|----------------------------|
| **Session**, **Connection**, **Stream**, **Channel** | handle object, manager, context blob |
| **Message**, **Frame**, **Packet**, **Command**, **Event** | struct / buffer / payload as the *concept name* |
| **Endpoint**, **Peer**, **Device**, **Port** (product) | client/server when roles differ |
| **Pipeline**, **Stage**, **Source**, **Sink** | “module A/B” without product names |
| **Capability**, **Mode**, **Profile** | unnamed config soup |
| **Error** product meanings (stream closed, busy, unsupported) | raw errno dump as the only language |

Name the **entity** (`Session`, `Device`), not the C mechanism (`void *`,
“opaque wrapper”). Mechanism → code or ADR.

## Error semantics at SDK boundaries

When errors are product language, define the **meaning**. Also decide (in
CONTEXT as short meanings, or ADR if hard to reverse):

- **Retryability** — caller may retry, must not, or only after re-open
- **Channel** — sync return code vs async event/callback
- **Stable identity** — which codes are ABI-stable vs internal
- **errno / OS mapping** — passthrough, translate, or never expose
- **Ownership on failure** — who frees buffers/handles if the call fails

Numeric tables stay in headers; CONTEXT keeps the shared meanings.
