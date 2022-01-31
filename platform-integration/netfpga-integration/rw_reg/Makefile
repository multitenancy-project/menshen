CC=gcc
CFLAGS=-O3 -Wall -I${DRIVER_FOLDER}

TARGET = rw_reg.so

all: $(TARGET)

rw_reg.so: rw_reg.c
	$(CC) $(CFLAGS) $^ -shared -fPIC -o $@

clean:
	rm -f $(TARGET)
