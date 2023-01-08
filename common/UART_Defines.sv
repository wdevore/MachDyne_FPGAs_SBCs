// 115200 bits per second = 8.68us
`define BAUD 115200
// 48MHz = ~20ns period
`define SOURCE_FREQ 48000000

// Note: the ACCUM_INC value is calculated using a handy Google spreadsheet I created:
// https://docs.google.com/spreadsheets/d/1_KMcRoW-iLCykuhmWQBCuXCK_7CK0AshxNRroGTbkPg/edit?usp=sharing
// Just select you system frequency (Clock cell), Baud and select Divider = 1.
// Then pick a "Clk count" value that is Green or with a higher Width size.
// 

// ---------- Settings for a 48MHz system clock ----------------
// Bit size of accumulator
`define ACCUMULATOR_WIDTH 20
// The number added to the accumulator on every clock tick.
`define ACCUM_INC 2517

// ---------- Settings for a 25MHz system clock ----------------
// Bit size of accumulator
// `define ACCUMULATOR_WIDTH 16
// The number added to the accumulator on every clock tick.
// `define ACCUM_INC 158

// Uncomment if you want to use 1 stop bit
`define ONE_STOP_BIT
// `define TWO_STOP_BITS