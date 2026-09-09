cmake_minimum_required(VERSION 3.16)
set(PICO_BOARD waveshare_rp2040_zero)
include(pico_sdk_import.cmake)
project(k1_firmware C CXX ASM)
pico_sdk_init()

add_executable(k1_firmware
    main/k1_main.c
    main/debounce.c
    main/keys.c
    main/usb_hid.c
)
target_include_directories(k1_firmware PRIVATE main)
target_link_libraries(k1_firmware pico_stdlib pico_util tinyusb_device)

# Debug logs on UART1 (GPIO 8/9, 115200) — keys occupy UART0's default
# GPIO 0/1. USB stays dedicated to the HID interface.
target_compile_definitions(k1_firmware PRIVATE
    PICO_DEFAULT_UART=1
    PICO_DEFAULT_UART_TX_PIN=8
    PICO_DEFAULT_UART_RX_PIN=9
)
pico_enable_stdio_uart(k1_firmware 1)
pico_enable_stdio_usb(k1_firmware 0)

pico_add_extra_outputs(k1_firmware)
