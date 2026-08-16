# Chat parity audit

- Web contract: `POST /chat/messages/:id/reaction` with `{ emoji }`.
- Web socket event: `chat:message:reaction`.
- Flutter now parses `senderAvatarUrl`, `senderAvatar`, `reactions`, and `senderId`.
- Flutter renders sender avatar, own/other alignment, heart action, reaction state, and socket updates.
