# Makefile for Perfect Server

TARGET = pollerbot
DEBUG = -g -Onone -Xcc -DDEBUG=1
OS = $(shell uname)
SWIFTC = swift
PERFECTLIB_PATH := /media/zhuowei/redhd/prog/swift/usr/lib
SWIFTC_FLAGS = -frontend $(DEBUG) -c -module-cache-path $(MODULE_CACHE_PATH) -emit-module -I $(PERFECTLIB_PATH) -I ../PerfectLib/linked/LibEvent \
	-I ../PerfectLib/linked/OpenSSL -I ../PerfectLib/linked/ICU -I ../PerfectLib/linked/SQLite3 -I ../PerfectLib/linked/LinuxBridge -I ../PerfectLib/linked/cURL_Linux
MODULE_CACHE_PATH = /tmp/modulecache
Linux_SHLIB_PATH = $(shell dirname $(shell dirname $(shell which swiftc)))/lib/swift/linux
SHLIB_PATH = -L$($(OS)_SHLIB_PATH)
LFLAGS = $(SHLIB_PATH) -g -luuid -lcurl -lswiftCore -lswiftGlibc -lFoundation $(PERFECTLIB_PATH)/PerfectLib.so -Xlinker -rpath -Xlinker $($(OS)_SHLIB_PATH)

all: modulecache $(TARGET)

modulecache:
	@mkdir -p $(MODULE_CACHE_PATH)

$(TARGET): $(TARGET).o
	clang++ $(LFLAGS) $@.o -o $@

$(TARGET).o: main.swift credentials.swift
	$(SWIFTC) $(SWIFTC_FLAGS) $< credentials.swift -o $@ -module-name $(subst .o,,$@) -emit-module-path $(subst .o,,$@).swiftmodule

clean:
	@rm *.o $(TARGET)
