#include "LibretroVfsStream.h"

#include <stdexcept>
#include <utility>

#include "ext/libretro.h"

CLibretroVfsStream::CLibretroVfsStream(retro_vfs_interface* vfsInterface, std::string path)
	: m_interface(vfsInterface)
	, m_path(std::move(path))
{
	if(!m_interface || !m_interface->open || !m_interface->close || !m_interface->size || !m_interface->tell ||
	   !m_interface->seek || !m_interface->read)
	{
		throw std::runtime_error("Incomplete libretro VFS interface.");
	}

	m_handle = m_interface->open(m_path.c_str(), RETRO_VFS_FILE_ACCESS_READ, RETRO_VFS_FILE_ACCESS_HINT_FREQUENT_ACCESS);
	if(!m_handle)
	{
		throw std::runtime_error("Unable to open file through libretro VFS.");
	}
}

CLibretroVfsStream::~CLibretroVfsStream()
{
	if(m_handle)
	{
		m_interface->close(m_handle);
	}
}

void CLibretroVfsStream::Seek(int64 position, Framework::STREAM_SEEK_DIRECTION direction)
{
	int seekPosition = RETRO_VFS_SEEK_POSITION_START;
	switch(direction)
	{
	case Framework::STREAM_SEEK_SET:
		seekPosition = RETRO_VFS_SEEK_POSITION_START;
		break;
	case Framework::STREAM_SEEK_CUR:
		seekPosition = RETRO_VFS_SEEK_POSITION_CURRENT;
		break;
	case Framework::STREAM_SEEK_END:
		seekPosition = RETRO_VFS_SEEK_POSITION_END;
		break;
	}

	if(m_interface->seek(m_handle, position, seekPosition) < 0)
	{
		throw std::runtime_error("Unable to seek through libretro VFS.");
	}
	m_isEof = false;
}

uint64 CLibretroVfsStream::Tell()
{
	const auto position = m_interface->tell(m_handle);
	if(position < 0)
	{
		throw std::runtime_error("Unable to tell position through libretro VFS.");
	}
	return static_cast<uint64>(position);
}

uint64 CLibretroVfsStream::Read(void* buffer, uint64 length)
{
	if(length == 0)
	{
		return 0;
	}

	const auto result = m_interface->read(m_handle, buffer, length);
	if(result < 0)
	{
		throw std::runtime_error("Unable to read through libretro VFS.");
	}
	if(result == 0)
	{
		m_isEof = true;
	}
	return static_cast<uint64>(result);
}

uint64 CLibretroVfsStream::Write(const void*, uint64)
{
	throw std::runtime_error("Unable to write to a libretro VFS read stream.");
}

bool CLibretroVfsStream::IsEOF()
{
	return m_isEof;
}

uint64 CLibretroVfsStream::GetLength()
{
	const auto length = m_interface->size(m_handle);
	if(length < 0)
	{
		throw std::runtime_error("Unable to get file size through libretro VFS.");
	}
	return static_cast<uint64>(length);
}
