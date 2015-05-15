# LOVE API Coverage

This is a pretty sad state of affairs! Please help!

* missing luasocket and lua-enet!
* love
   * missing some callbacks
   * love.focus
   * love.mousefocus
   * love.mousemoved
   * love.wheelmoved
   * love.mousepressed & love.mousereleased
      * stubbed, need to fire events
   * love.resize
      * should be easy-peasy
   * love.run
      * hate init needs some restructuring
   * love.threaderror
      * depends on hate.thread
   * love.visible
   * love.touchpressed
   * love.touchreleased
   * love.touchmoved
   * love.lowmemory
   * haven't touched joysticks! will need:
      * love.gamepadaxis
      * love.gamepadpressed
      * love.gamepadreleased
      * love.joystickadded
      * love.joystickaxis
      * love.joystickhat
      * love.joystickpressed
      * love.joystickreleased
      * love.joystickremoved

## Not yet started

* love.audio & love.sound (dependent)
* love.font
  * image fonts will definitely be supported first, no need for FreeType for those.
* love.image
* love.keyboard
* love.joystick
* love.mouse
* love.physics
* love.thread

## Started

* love.math
* love.keypressed & love.keyreleased
  * Missing many key codes, otherwise done.
* love.errhand
  * Missing too many features to implement 100%, but the callback is done.
* love.event
  * It's only the most trivial stuff so far.
* love.filesystem
  * Some issues with base path, missing functions
* love.graphics
  * Barely functional. Needs tons of work.
* love.window
  * Half done or so.
* love.textinput
  * I think I just need to make this emit, the handler seems done.

## Complete

* love.system
* love.timer
* love.draw
* love.update
* love.load
* love.quit
