## 2024-05-23 - Visual Alignment with Emojis

**Learning:** When formatting CLI tables that contain emojis, standard string padding methods (`ljust`/`rjust`) are insufficient because emojis typically have a string length of 1 but a visual width of 2 character cells. This causes column misalignment.
**Action:** When padding a string that contains an emoji, compensate by reducing the padding width by 1 for each emoji present, or use a library that handles visual width (like `tty-table`). For simple cases without extra dependencies, manual adjustment works but requires care.
