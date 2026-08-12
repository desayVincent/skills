# CONTEXT.md format

Load when creating or editing a glossary file. **Layout choice and write gate**
live in [SKILL.md](SKILL.md); this file is output shape only.

## Structure

```md
# {Context Name}

{One or two sentences: what this context is and why it exists.}

## Language

**Session**:
A living association between a local endpoint and a peer for one use period.
_Avoid_: Connection (if Connection means transport only), handle, context

**Stream**:
A flow of frames inside a Session.
_Avoid_: Channel (if Channel means hardware), pipe

**Frame**:
One protocol unit with defined layout semantics.
_Avoid_: Buffer, packet (if Packet is the transport unit)
```

## Rules

- **Opinionated.** One canonical word; others under `_Avoid_`.
- **Tight.** One or two sentences. What it *is*, not every operation.
- **Project-specific.** Product Session / Stream / “busy” stay; general C
  (mutex, malloc as mechanism) stay out.
- **Stable product meanings.** Record meanings callers share; put numeric
  enums, paths, and mechanisms in code or ADRs.
- **Group** under subheadings when clusters appear (Transport, Media, Lifecycle).

## Multi-context map shape

```md
# Context Map

## Contexts

- [Media](./media/CONTEXT.md) — capture, process, present streams
- [Transport](./transport/CONTEXT.md) — sessions and delivery
- [Platform](./platform/CONTEXT.md) — board and device bring-up

## Relationships

- **Media → Transport**: Media emits Frames; Transport carries Packets
- **Transport → Platform**: link status and Device identity from Platform
```

Unclear which context → ask (see skill process step 1).
