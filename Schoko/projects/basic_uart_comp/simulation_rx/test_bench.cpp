#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <cstdint>

// Files generated by Verilator
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VTop.h"
// #include "VTop_SPIMaster.h" // not really needed
// Needed for the exposed public fields via "*verilator public*"
// and Top module
// #include "VTop___024unit.h"
#include "VTop__Syms.h"

// Test bench files
#include "module.h"

float freq = 10000000.0;

float picoseconds = 1.0;
float period = 1.0/freq*1000000000.0;
float hPeriod = period / 2.0;
float picoCnt = 0.0;

// ------------------------------------------------------------
// Misc
// ------------------------------------------------------------
int step(int timeStep, TESTBENCH<VTop> *tb, VTop *top)
{
    if (picoCnt > hPeriod-1.0) {
        top->sysClock ^= 1;
        picoCnt = 0;
        // exit(1);
    } else {
        picoCnt += 1.0;
    }
    // std::cout << "picoCnt: " << picoCnt << std::endl;

    tb->eval();
    tb->dump(timeStep);
    timeStep++;

    return timeStep;
}

int main(int argc, char *argv[])
{
    std::cout << "Starting test bench" << std::endl;

    Verilated::commandArgs(argc, argv);

    // initialize Verilog (aka SystemVerilog) module
    TESTBENCH<VTop> *tb = new TESTBENCH<VTop>();

    tb->setup();

    VTop *top = tb->core();
    // Not really needed unless you want to mess with sub-modules
    // VTop_Top *topTop = top->Top;
    // VTop_SPIMaster *spiMaster = topTop->master;
    std::cout << "period: " << period << std::endl;
    std::cout << "hPeriod: " << hPeriod << std::endl;

    vluint64_t timeStep = 0;
    int duration = 0;

    top->sysClock = 0;

    // Allow any initial blocks to execute
    tb->eval();
    timeStep = step(timeStep, tb, top);

    // Run enough clocks for module to do its thing.
    duration = 1000000 + timeStep;
    while (timeStep < duration)
    {
        // std::cout << "t: " << timeStep << std::endl;
        timeStep = step(timeStep, tb, top);
    }


    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--
    std::cout << "Finish TB." << std::endl;
    // :--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--:--

    tb->shutdown();

    delete tb;

    exit(EXIT_SUCCESS);
}
