# Feature 12 — Visual Layer
*Plummet · Game Jam Build*

## Purpose

The visual layer renders the game state to the screen. It is intentionally decoupled from all game logic — no rendering code touches game state directly, and no game logic code knows anything about how things look. This separation means the entire visual style can be swapped out without touching a single line of game logic.

---

## Scope

  1. Gravity animation — the biggest missing piece. Pieces currently snap to new positions after a clear. Watching them slide down is very satisfying,      
  especially during a deep cascade. You'd snapshot column positions before/after apply_gravity(), then animate each piece from its old row to its new row in
   AnimLayer.                                                                                                                                               
                                                                                                                                                            
  2. Landing impact burst — on piece landing, spawn 4–6 small dots that fly outward from the cell and fade. One draw_circle per dot, takes maybe 20 lines.  
  This is the "thud" visual equivalent and makes every drop feel physical.                                                                                  
                                                                                                                                                            
  3. AI drop preview — 300ms before the AI drops, briefly highlight the column with a faint overlay. Gives the player a moment to anticipate and react.     
  Makes the AI feel intentional instead of instant.
                                                                                                                                                            
  4. Column hover highlight — draw a subtle vertical strip behind the hovered column (faint white, ~10% alpha). The ghost piece already shows the landing   
  row, but a full-column highlight makes the target feel more "locked in."
                                                                                                                                                            
  5. Score counter tween — instead of snapping the score label to the new value, tick it up over ~20 frames. Small effect but very satisfying when a big    
  cascade resolves.                       
                                                                                                                                                            
  6. Piece trail while falling — draw 2–3 ghost copies of the falling piece behind it at decreasing alpha. Fast to add to _draw_drop_anim, makes the drop   
  feel speedy.                            
                                                                                                                                                            
  The biggest feel win for the least code is probably gravity animation — cascades are the core loop and they currently feel incomplete without it. Landing 
  burst is a close second since it fires on every single player action.

7.  Board-level effects:                                                                                                                                    
  - Column fill warning — column turns red/pulses when 1–2 cells from full. Pressure feedback.                                                              
  - Piece lock flash — brief white flash on the whole column when a piece can no longer be dropped there (full column = frozen out).                        
  - Clear line sweep — thin horizontal/diagonal line sweeps across matched cells just before they flash, tracing the run visually.                          
  - Board idle breathe — very subtle scale pulse (0.999→1.001) on the board when nothing is happening. Almost imperceptible but makes it feel alive.  
8. Turn feedback:                                                                                                                                 
  - Your turn indicator pop — the "YOUR TURN" text bounces/scales in when control returns to the player.                                                    
  - AI "thinking" dots — during the AI's turn, show animated dots (...) in the turn indicator instead of "AI TURN". Makes the AI feel present.              
  - Column rejection shake — if player clicks a frozen/full column, that column does a brief horizontal shake. No-feedback clicks feel broken.   
 9. Piece and queue:                                                                                                                                          
  - Queue slide — when a piece is consumed, the next piece slides down into position instead of snapping.                                                 
  - Incoming piece drop preview — the piece in the queue subtly bounces to draw attention to what's coming.                                                 
  - Modifier badge pulse — modifier badges on your queued pieces pulse gently, reminding you they're armed.                                                 
                                                                                                                                                            
 10. Score and cascade:                                                                                                                                        
  - Multiplier escalation color — score popups shift from yellow → orange → red as multiplier increases. Cascade depth 3+ glows.                          
  - Match-end score comparison — when the match ends, the two scores dramatically count up side by side before revealing the winner.                        
  - Chip earn flash — a "+1 chip" micro-popup near the score when a clear earns chips.      

Not in scope: animations (feature 11), sound (feature 11), shop UI layout (feature 07), run summary screen (feature 09).
