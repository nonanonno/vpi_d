#include <vpi/Image.h>
#include <vpi/Status.h>
#include <vpi/Stream.h>
#include <vpi/algo/ConvertImageFormat.h>
#include <vpi/algo/Convolution.h>

const int VpiMaxStatusMessageLength = VPI_MAX_STATUS_MESSAGE_LENGTH;
const VPIImageFormat VpiImageFormatU8 = VPI_IMAGE_FORMAT_U8;
const VPIImageFormat VpiImageFormatRGB8 = VPI_IMAGE_FORMAT_RGB8;
const VPIImageFormat VpiImageFormatBGR8 = VPI_IMAGE_FORMAT_BGR8;
const VPIImageFormat VpiImageFormatInvalid = VPI_IMAGE_FORMAT_INVALID;
const VPIStatus VpiErrorInvalidArgument = VPI_ERROR_INVALID_ARGUMENT;
const VPIImageBufferType VpiImageBufferHostPitchLinear = VPI_IMAGE_BUFFER_HOST_PITCH_LINEAR;
