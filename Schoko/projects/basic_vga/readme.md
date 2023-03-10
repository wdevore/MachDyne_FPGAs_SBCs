# Description
A very basic test of VGA. A solid color is displayed.

The setup is: 640x480 60fps

## Tasks
- Pixel clock (via PLL)
- Raster signals
- Rendering
- Video out

# VGA

## Configuration

| Parameter	| Horizontal | Vertical    |
| :---	         | :---:    | :---:    |
| Active Pixels	 | 640      | 480      |
| Front Porch    | 16       | 10       |
| Sync Width     | 96       | 2        |
| Back Porch     | 48       | 33       |
| Total Blanking | 160      | 45       |
| Total Pixels   | 800      | 525      |
| Sync Polarity  | negative | negative |

Horz Total Pixels = 640 + 16 + 96 + 48 = 800

Vert Total Pixels = 480 + 10 +2 + 33 = 525


# Links
- https://projectf.io/posts/fpga-graphics/
- http://tinyvga.com/vga-timing/640x480@73Hz
- https://zipcpu.com/blog/2017/06/02/generating-timing.html 
- https://www.youtube.com/watch?v=5xY3-Er72VU uses the upduino 3.0
- https://imuguruza.github.io/blog/vga
- https://www.youtube.com/watch?v=ZNunxg7o8l0  Great scott
- https://www.fpga4fun.com/PongGame.html  pong
- https://ktln2.org/2018/01/23/implementing-vga-in-verilog/
- https://vanhunteradams.com/DE1/VGA_Driver/Driver.html
- https://www.instructables.com/Video-Interfacing-With-FPGA-Using-VGA/
- https://www.instructables.com/Design-of-a-Simple-VGA-Controller-in-VHDL/
- https://blog.waynejohnson.net/doku.php/generating_vga_with_an_fpga
- https://nandland.com/project-9-vga-introduction-driving-test-patterns-to-vga-monitor/ 
 

# PLL

```
ecppll -i 48 --reset -o 25.175 --highres -f pll.v

Pll parameters:
Refclk divisor: 13
Feedback divisor: 3
clkout0 divisor: 50
clkout0 frequency: 25.1748 MHz
clkout1 divisor: 22
clkout1 frequency: 25.1748 MHz
clkout1 phase shift: 0 degrees
VCO frequency: 553.846
```
