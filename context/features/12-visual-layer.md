# Feature 12 — Visual Layer
*Plummet · Game Jam Build*

## Purpose

The visual layer renders the game state to the screen. It is intentionally decoupled from all game logic — no rendering code touches game state directly, and no game logic code knows anything about how things look. This separation means the entire visual style can be swapped out without touching a single line of game logic.

---

## Scope

- Rendering interface (the contract between game logic and visuals)
- Board rendering
- Piece rendering (both colors, all types)
- UI rendering (scores, turn indicators, piece queue, chip count)
- State overlays (frozen columns, locked cells, modifier indicators)
- Theme system (how to swap visuals later)

Not in scope: animations (feature 11), sound (feature 11), shop UI layout (feature 07), run summary screen (feature 09).

---

## Core Design Principle: The Rendering Interface

The game logic never renders anything directly. Instead, it produces a **render state** — a plain data snapshot of everything that needs to be drawn. The visual layer reads this snapshot and draws it. Nothing flows the other way.

This means:

- The game logic has no knowledge of colors, sizes, fonts, or sprites.
- The visual layer has no knowledge of scores, rules, or game flow.
- Swapping the visual layer means replacing the renderer, not touching the game.

---

## The Render State

The render state is a data structure produced by the game logic each frame (or each time the board changes). It contains everything the visual layer needs and nothing else.

### Contents of the render state

**Board**
- For each cell: column, row, occupant (empty / player / AI), piece type, modifier list, locked status, frozen status

**Piece queue**
- Player's next 2 pieces: type and modifier list for each

**Scores**
- Player score (current)
- AI score (current)
- Score delta from last turn (for popup positioning hint)

**Turn state**
- Whose turn it is (player or AI)
- Turns remaining for each player
- Whether input is currently accepted (false during animations)

**Active effects**
- List of frozen columns (column index + turns remaining)
- List of locked cells (column, row)
- Any active board transformations (e.g. gravity direction for The Inverter)

**Match state**
- Current act and match number
- Current enemy name and gimmick description (one line, for UI display)

**Chip count**
- Player's current chips (displayed during and between matches)

The render state is read-only from the visual layer's perspective. The visual layer never modifies it.

---

## Rendering Interface

The visual layer must implement these operations. What they do visually is up to the theme.

| Operation | When called | Input |
|---|---|---|
| Draw board | Each frame | Full render state |
| Draw cell | Per cell | Cell data (occupant, type, modifiers, flags) |
| Draw piece queue | Each frame | Queue data (2 pieces) |
| Draw scores | Each frame | Both player scores, delta |
| Draw turn indicator | Each frame | Whose turn, turns remaining |
| Draw frozen overlay | When column is frozen | Column index, turns remaining |
| Draw locked cell | Per locked cell | Column, row |
| Draw enemy info | Each frame | Enemy name, gimmick description |
| Draw chip count | Each frame | Chip value |
| Draw modifier badge | Per modifier on a piece | Modifier name, slot index |

Each operation receives only what it needs from the render state. No operation receives the full game state object.

---

## Board Layout

The board occupies the center of the screen. The layout values below are the default — themes may override them.

| Element | Default value |
|---|---|
| Cell size | 48×48 px |
| Cell gap | 4 px |
| Board width | 7 cells (380 px total with gaps) |
| Board height | 12 cells (628 px total with gaps) |
| Board origin | Centered horizontally, vertically centered with room for UI above and below |

UI panels flank the board:
- Left panel: player score, player turn indicator, player piece queue
- Right panel: AI score, AI turn indicator, chip count, enemy name and gimmick
- Bottom strip: match info (act, match number, turns remaining)

---

## Theme System

A theme is a self-contained set of visual definitions. Swapping themes means swapping one theme object — nothing else changes.

### What a theme defines

**Colors**
- Player piece color
- AI piece color
- Empty cell color
- Board background color
- Locked cell color
- Frozen column overlay color
- UI background color
- UI text color (primary, secondary)
- Score popup colors (positive, bonus)
- Modifier badge colors (one per modifier)

**Shapes**
- Cell shape: square, rounded square, or circle
- Piece shape: same as cell, or defined separately
- Board border style: none, thin line, or shadow

**Typography**
- Score font (size, weight)
- Label font (size, weight)
- Modifier badge font (size)
- Combo announcement font (size, weight)

**Piece appearance**
- How piece types are distinguished visually: by shape, by icon, by pattern, or by border style
- How modifiers are displayed on pieces: badge (text label), icon, or color tint
- How the player's and AI's pieces are distinguished: by color only, or also by shape

**Grid appearance**
- Whether the empty grid is visible or invisible
- Whether column guides are shown (vertical lines from top to bottom of board)
- Whether row numbers are shown

### Jam theme (default)

The default theme for the jam build. Functional, clean, no art assets required.

- Player pieces: solid filled circle, purple
- AI pieces: solid filled circle, teal
- Empty cells: faint grey outline square
- Board background: dark grey
- Locked cells: grey filled square with a lock icon (text: "■")
- Frozen columns: blue tint overlay on affected column
- Modifier badges: small colored pill in the corner of the piece, one letter abbreviation (E, M, H, A, C, D)
- Piece types distinguished by border: Normal (no border), Weighted (thick border), Ghost (dashed border), Volatile (jagged border)
- UI: flat panels, monospace font, no decorative elements

### Swap-ready theme slots

Design the theme system with at least these future themes in mind:

- **Pixel art theme** — replaces all shapes with sprite assets; same interface, different draw calls
- **Minimal theme** — high contrast, no outlines, pure geometry
- **Neon theme** — dark background, glowing pieces, bloom effects

The rendering interface must not assume any specific visual output — a theme that draws sprites and a theme that draws vector shapes must both satisfy the same interface.

---

## Modifier Visibility on Pieces

Modifiers must be visible on pieces in the queue and on the board. The default approach:

- Each piece can show up to 3 modifier badges simultaneously.
- Badges are placed in the bottom-left, bottom-center, and bottom-right of the cell.
- Each badge shows a one or two character abbreviation and uses a distinct color per modifier type.
- On hover (or tap on mobile), expand the badge to show the full modifier name.

Modifier badge colors (jam theme defaults):

| Modifier | Abbreviation | Color |
|---|---|---|
| Echo | EC | Purple |
| Magnet | MG | Blue |
| Heavy | HV | Orange |
| Anchor | AN | Grey |
| Catalyst | CT | Yellow |
| Double Drop | DD | Green |

---

## Column Interaction

The player selects a column to drop into. The visual layer must handle:

- **Hover state**: highlight the column the cursor is over (or the selected column on touch/keyboard). Show a ghost piece at the top of the column indicating where the piece will land.
- **Invalid state**: if a column is full or frozen, show it as unselectable (greyed out, no ghost piece, cursor change if on desktop).
- **Drop confirmation**: on click/tap, the drop animation begins (feature 11).

The hover ghost piece should show the correct piece type and modifier badges for the player's current piece.

---

## Responsive Layout

The board must be playable at a range of screen sizes. Two layout modes:

**Desktop (wide)**
Left panel | Board | Right panel — all three visible simultaneously.

**Mobile / narrow**
Board centered, UI panels collapsed above and below the board. Scores shown above, queue and chip count shown below. Enemy info accessible via a tap/expand gesture.

The cell size should scale to fit the viewport while maintaining the 7×12 grid. Minimum cell size is 32×32 px. Below this, the layout breaks and should show a "rotate your device" prompt.

---

## Accessibility

- Player and AI pieces must be distinguishable by shape or pattern, not color alone. The jam theme uses circles for both but adds a distinct inner mark to AI pieces (e.g. a small square center dot).
- All text must meet a minimum contrast ratio of 4.5:1 against its background.
- Modifier badges must not rely solely on color — the abbreviation text must always be present.
- Frozen and locked cell states must have a visual indicator beyond color (pattern or icon).

---

## Edge Cases

- A cell that is both part of a clear and has an Anchor modifier still renders normally until the clear animation runs — the visual layer shows current board state, not predicted state.
- The ghost piece preview in a frozen column should not appear — the column hover state switches to invalid.
- If the board is in gravity-flip mode (The Inverter), the board renders upside down — row 11 at the bottom, row 0 at the top. The column interaction remains the same (player always drops from the top of the screen).
- Locked cells from The Gravedigger must be visually distinct from both empty cells and normal pieces — they are permanent obstacles, not playable pieces.

---

## Acceptance Criteria

- The board renders all 84 cells correctly at the start of a match (all empty).
- Player and AI pieces render in distinct colors and are distinguishable without color.
- All 4 piece types are visually distinguishable from each other.
- All 6 modifier badges render correctly on pieces in the queue and on the board.
- Frozen columns display a visible overlay and reject hover/ghost piece rendering.
- Locked cells display as distinct from empty cells and normal pieces.
- The column hover state shows a ghost piece at the correct landing row.
- The layout adapts correctly between desktop and mobile viewport sizes.
- The full visual layer can be replaced by swapping the theme object with no changes to game logic files.
- All visual states are driven solely by the render state — no visual code reads game state directly.

---

## Dependencies

- Feature 01 — Board engine (source of board cell data)
- Feature 05 — Piece bag + modifiers (source of queue and modifier data)
- Feature 03 — Scoring system (source of score data)
- Feature 04 — AI opponent (source of turn state)

## Required by

- Feature 11 — Animations + juice (layers animation over the visual layer)
