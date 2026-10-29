import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly


@cocotb.test()
async def test_rc4(dut):

    cocotb.start_soon(
        Clock(dut.CLK_IN, 10, unit="ns").start()
    )

    dut.RESET_N_IN.value = 0
    dut.KEY_SIZE_IN.value = 3
    dut.KEY_BYTE_IN.value = 0
    dut.PLAIN_BYTE_IN.value = 0
    dut.START_IN.value = 0
    dut.STOP_IN.value = 0
    dut.HOLD_IN.value = 0

    # Reset the design
    for _ in range(3):
        await RisingEdge(dut.CLK_IN)

    dut.RESET_N_IN.value = 1

    # Wait for S[0:255] initialization
    for _ in range(260):
        await RisingEdge(dut.CLK_IN)

    # RC4 key: "Key"
    key = [ord("K"), ord("e"), ord("y")]

    dut.KEY_BYTE_IN.value = key[0]

    # Start key-copy process
    dut.START_IN.value = 1
    await RisingEdge(dut.CLK_IN)

    dut.START_IN.value = 0

    # Clear START_KEY_CPY_OUT
    await RisingEdge(dut.CLK_IN)

    # Copy key bytes
    for key_byte in key:
        dut.KEY_BYTE_IN.value = key_byte
        await RisingEdge(dut.CLK_IN)

    # Wait for key scheduling to finish
    while True:
        await RisingEdge(dut.CLK_IN)
        await ReadOnly()

        if int(dut.READ_PLAINTEXT_OUT.value) == 1:
            break

    # Leave ReadOnly phase before changing inputs
    await Timer(1, unit="ns")

    print("RC4 key scheduling complete")

    plaintext = b"Plaintext"

    expected = [
        0xBB, 0xF3, 0x16, 0xE8,
        0xD9, 0x40, 0xAF, 0x0A,
        0xD3
    ]

    results = []

    for byte in plaintext:
        dut.PLAIN_BYTE_IN.value = byte

        await RisingEdge(dut.CLK_IN)
        await Timer(1, unit="ns")

        encrypted_byte = int(dut.ENC_BYTE_OUT.value)
        results.append(encrypted_byte)

        print(
            f"Input: 0x{byte:02X}, "
            f"Output: 0x{encrypted_byte:02X}"
        )

    print("Expected:", [f"{x:02X}" for x in expected])
    print("Actual:  ", [f"{x:02X}" for x in results])

    assert results == expected

    print("RC4 Cocotb test passed!")
