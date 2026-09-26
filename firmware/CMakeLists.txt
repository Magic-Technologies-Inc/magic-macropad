cmake_minimum_required(VERSION 3.16)
set(PICO_BOARD waveshare_rp2040_zero)
include(pico_sdk_import.cmake)
project(k1_firmware C CXX ASM)
pico_sdk_init()

add_executable(k1_firmware
    main/k1_main.c
    main/debounce.c
    main/keys.c
    main/keysync.c
    main/led.c
    main/usb_hid.c
)
pico_generate_pio_header(k1_firmware ${CMAKE_CURRENT_LIST_DIR}/main/ws2812.pio)
target_include_directories(k1_firmware PRIVATE main)
target_link_libraries(k1_firmware pico_stdlib pico_util hardware_pio tinyusb_device)

# Debug logs on UART0 (GPIO 0/1, 115200); USB stays dedicated to the HID
# interface.
pico_enable_stdio_uart(k1_firmware 1)
pico_enable_stdio_usb(k1_firmware 0)

pico_add_extra_outputs(k1_firmware)
