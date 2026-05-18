 Board atmosphere                                                                                                                                          
  - Board edge glow by turn — the board border subtly glows player color on your turn, AI color on theirs. Instant ownership read.                          
  - Cascade heat — board background color temperature shifts warmer (toward orange/red) as cascade depth increases, cools back after. Makes deep chains feel
   volcanic.                                                                                                                                                
  - Frozen column frost overlay — draw a faint icy texture (or just blue-tinted hatching) over frozen columns. Currently they just reject; this makes the   
  state readable at a glance.                                                                                                                               
                                                                                                                                                            
  Piece feedback                                                                                                                                            
  - Drop shadow under falling piece — small soft ellipse on the landing cell that shrinks as piece approaches. Communicates distance.                     
  - Modifier trigger flash — when a modifier activates (Echo, Magnet, etc.), the piece briefly pulses its accent color. Right now modifiers are invisible   
  mid-play.                                                                                                                                               
  - Piece glow on land — piece briefly blooms to 120% of its color saturation then settles. The "thud" has visual weight.                                   
                                                                                                                                                            
  Score / cascade                             
  - Score milestone pop — crossing 500, 1000, 2000 etc. triggers a larger centered text pop (like combo announcements). Gives the score counter drama.      
  - Cascade counter badge — persistent "×3" badge in the corner that ticks up each cascade level and fades after the chain ends. Makes depth legible      
  mid-play.                                                                                                                                                 
                                                                                                                                                          
  Meta / game state                                                                                                                                         
  - Turn counter urgency — last 10 turns, the turn counter label pulses red on each new turn.                                                             
  - Enemy portrait reactions — a simple AI portrait (even just a face made of shapes) that reacts: neutral, smug when AI scores big, startled when player   
  gets a chain. Huge personality for ~50 lines.                                                                                                           
                                                                                                                                                            
  If sound ever comes in scope                                                                                                                              
  - Cascade pitch escalation (each depth level raises the clear sound a half-step) is the single biggest feel upgrade available and costs almost nothing
  once audio is wired.                                                                                                                                      
                                                                                                                                                          
  The ones with the best ratio right now are frozen column frost, cascade heat, and modifier trigger flash — they fill feedback gaps that currently exist,  
  rather than adding redundant polish on things that already feel good.                                                                                     
                                                                            