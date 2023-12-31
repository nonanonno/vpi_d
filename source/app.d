import std.stdio;
import vpi;
import std.format;
import gamut;
import std.conv;

void checkStatus(int line = __LINE__)(VPIStatus status)
{
	if (status != VPI_SUCCESS)
	{
		char[VpiMaxStatusMessageLength] buffer;
		vpiGetLastStatusMessage(buffer.ptr, buffer.sizeof);
		auto e = format!"%s : %s"(vpiStatusGetName(status), buffer);
		throw new Exception(e);
	}
}

void main(string[] args)
{
	VPIImage image;
	VPIImage imageRGB;
	VPIImage gradient;
	VPIStream stream;
	VPIBackend backend;

	try
	{
		if (args.length != 3)
		{
			throw new Exception(format!"Usage: %s <cpu|pva|cuda> <input image>"(args[0]));
		}

		auto strBackend = args[1];
		auto strInputFilename = args[2];

		Image inputImage;
		inputImage.loadFromFile(strInputFilename, LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT | LOAD_NO_ALPHA);
		if (inputImage.isError())
		{
			throw new Exception(inputImage.errorMessage.to!string);
		}

		switch (strBackend)
		{
		case "cpu":
			backend = VPI_BACKEND_CPU;
			break;
		case "cuda":
			backend = VPI_BACKEND_CUDA;
			break;
		case "pva":
			backend = VPI_BACKEND_PVA;
			break;
		default:
			new Exception(
				"Backend '" ~ strBackend ~ "' not recognized, it must be either cpu, cuda or pva.");
		}

		checkStatus(vpiStreamCreate(0, &stream));
		scope (exit)
			vpiStreamDestroy(stream);

		checkStatus(imageCreateWrapperGamut(inputImage, 0, &imageRGB));
		scope (exit)
			vpiImageDestroy(imageRGB);

		checkStatus(vpiImageCreate(inputImage.width, inputImage.height, VpiImageFormatU8, 0, &image));
		scope (exit)
			vpiImageDestroy(image);

		checkStatus(vpiSubmitConvertImageFormat(stream, VPI_BACKEND_CUDA, imageRGB, image, null));

		checkStatus(vpiImageCreate(inputImage.width, inputImage.height, VpiImageFormatU8, 0, &gradient));

		float[3 * 3] kernel = [1, 0, -1, 0, 0, 0, -1, 0, 1];

		checkStatus(vpiSubmitConvolution(stream, backend, image, gradient, kernel.ptr, 3, 3, VPI_BORDER_ZERO));

		checkStatus(vpiStreamSync(stream));

		{
			VPIImageData outData;
			checkStatus(vpiImageLockData(gradient, VPI_LOCK_READ, VpiImageBufferHostPitchLinear, &outData));
			scope (exit)
				checkStatus(vpiImageUnlock(gradient));

			assert(outData.bufferType == VpiImageBufferHostPitchLinear);

			Image outputImage;
			outputImage.createViewFromData(outData.buffer.pitch.planes[0].data, outData.buffer.pitch.planes[0].width, outData
					.buffer.pitch.planes[0].height, PixelType.l8, outData
					.buffer.pitch.planes[0].pitchBytes);

			outputImage.saveToFile("edges_" ~ strBackend ~ ".png");
		}

	}
	catch (Exception e)
	{
		writeln(e.msg);
		return;
	}

}

VPIStatus imageCreateWrapperGamut(ref Image gam, ulong flags, VPIImage* img)
{
	VPIImageData imgData;

	VPIStatus status = fillImageData(gam, &imgData);
	if (status != VPI_SUCCESS)
	{
		return status;
	}

	return vpiImageCreateWrapper(&imgData, null, flags, img);
}

VPIStatus fillImageData(ref Image gam, VPIImageData* imgData)
{
	assert(imgData);
	if (!gam.hasData)
	{
		return VpiErrorInvalidArgument;
	}
	VPIImageFormat fmt = ToImageFormatFromGamut(gam.type);
	if (fmt == VpiImageFormatInvalid)
	{
		return VpiErrorInvalidArgument;
	}

	imgData.bufferType = VpiImageBufferHostPitchLinear;

	imgData.buffer.pitch.format = fmt;
	imgData.buffer.pitch.numPlanes = 1;
	imgData.buffer.pitch.planes[0].width = gam.width;
	imgData.buffer.pitch.planes[0].height = gam.height;
	imgData.buffer.pitch.planes[0].pitchBytes = gam.pitchInBytes;
	imgData.buffer.pitch.planes[0].data = cast(void*) gam.allPixelsAtOnce().ptr;
	imgData.buffer.pitch.planes[0].pixelType = vpiImageFormatGetPlanePixelType(fmt, 0);

	return VPI_SUCCESS;
}

VPIImageFormat ToImageFormatFromGamut(PixelType type)
{
	switch (type)
	{
	case PixelType.rgb8:
		return VpiImageFormatBGR8;
	default:
		return VpiImageFormatInvalid;
	}
}
