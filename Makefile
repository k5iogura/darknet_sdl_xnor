#export PKG_CONFIG_PATH=/home/kenji/libs2/opencv-2.4.13-x86_linux_gcc/installed/lib/pkgconfig:/home/kenji/libs/SDL2_x86/lib/pkgconfig:/home/kenji/libs/ffmpeg_x86+x264/lib/pkgconfig
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
GPU=1
CUDNN=0
OPENCV?=1
OPENMP=0
DEBUG?=0

ARCH= \
      -gencode arch=compute_30,code=sm_30 \
      -gencode arch=compute_35,code=sm_35 \
      -gencode arch=compute_50,code=[sm_50,compute_50] \
      -gencode arch=compute_52,code=[sm_52,compute_52]

# This is what I use, uncomment if you know your arch and want to specify
# ARCH= -gencode arch=compute_52,code=compute_52

VPATH=./src/:./examples
SLIB=libdarknet.so
ALIB=libdarknet.a
EXEC=darknet
OBJDIR=./obj/

CC=gcc
NVCC=nvcc 
AR=ar
ARFLAGS=rcs
OPTS=-Ofast
LDFLAGS= -lm -pthread 
COMMON= -Iinclude/ -Isrc/
ifeq ($(GPU),0)
COMMON+= -DAI2
CC+= -std=gnu11
endif
CFLAGS=-Wall -Wno-unknown-pragmas -Wfatal-errors -fPIC

ifeq ($(OPENMP), 1) 
CFLAGS+= -fopenmp
endif

ifeq ($(DEBUG), 1) 
OPTS=-O0 -g -pg
endif

CFLAGS+=$(OPTS)

ifeq ($(OPENCV), 1) 
COMMON+= -DOPENCV
#CFLAGS+= -DOPENCV -DSDL2 -DSINGLE_THREAD_SDL
CFLAGS+= -DOPENCV -DSDL2
#COMMON+= -Wno-unused-function -Wno-unused-result -Wno-unused-variable
#COMMON+= -Wno-return-type -Wno-format-security -Wno-pointer-sign
#COMMON+= -Wno-maybe-uninitialized -Wno-implicit-int
LDFLAGS+= `pkg-config --libs opencv` 
COMMON+= `pkg-config --cflags opencv` 
LDFLAGS+= `pkg-config --libs sdl2` 
COMMON+= `pkg-config --cflags sdl2` 
OBJ+=sdl_image.o
endif

ifeq ($(GPU), 1) 
COMMON+= -DGPU -I/usr/local/cuda/include/
CFLAGS+= -DGPU
LDFLAGS+= -L/usr/local/cuda/lib64 -lcuda -lcudart -lcublas -lcurand
endif

ifeq ($(CUDNN), 1) 
COMMON+= -DCUDNN 
CFLAGS+= -DCUDNN
LDFLAGS+= -lcudnn
endif

OBJ+=gemm.o utils.o cuda.o deconvolutional_layer.o convolutional_layer.o list.o image.o activations.o im2col.o col2im.o blas.o crop_layer.o dropout_layer.o maxpool_layer.o softmax_layer.o data.o matrix.o network.o connected_layer.o cost_layer.o parser.o option_list.o detection_layer.o route_layer.o box.o normalization_layer.o avgpool_layer.o layer.o local_layer.o shortcut_layer.o activation_layer.o rnn_layer.o gru_layer.o crnn_layer.o demo.o batchnorm_layer.o region_layer.o reorg_layer.o tree.o  lstm_layer.o
ifeq ($(GPU),0)
OBJ+=xnor_layer.o binary_convolution.o
endif
EXECOBJA=captcha.o lsd.o super.o voxel.o art.o tag.o cifar.o go.o rnn.o rnn_vid.o compare.o segmenter.o regressor.o classifier.o coco.o dice.o yolo.o detector.o  writing.o nightmare.o swag.o darknet.o 
ifeq ($(GPU), 1) 
LDFLAGS+= -lstdc++ 
OBJ+=convolutional_kernels.o deconvolutional_kernels.o activation_kernels.o im2col_kernels.o col2im_kernels.o blas_kernels.o crop_layer_kernels.o dropout_layer_kernels.o maxpool_layer_kernels.o network_kernels.o avgpool_layer_kernels.o
endif

EXECOBJ = $(addprefix $(OBJDIR), $(EXECOBJA))
OBJS = $(addprefix $(OBJDIR), $(OBJ))
DEPS = $(wildcard src/*.h) Makefile include/darknet.h

#all: obj backup results $(SLIB) $(ALIB) $(EXEC)
all: obj  results $(SLIB) $(ALIB) $(EXEC)


$(EXEC): $(EXECOBJ) $(ALIB)
	$(CC) $(COMMON) $(CFLAGS) $^ -o $@ $(LDFLAGS) $(ALIB)

$(ALIB): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

$(SLIB): $(OBJS)
	$(CC) $(CFLAGS) -shared $^ -o $@ $(LDFLAGS)

$(OBJDIR)%.o: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

$(OBJDIR)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@

obj:
	mkdir -p obj
backup:
	mkdir -p backup
results:
	mkdir -p results

.PHONY: clean

clean:
	rm -rf $(OBJS) $(SLIB) $(ALIB) $(EXEC) $(EXECOBJ)

