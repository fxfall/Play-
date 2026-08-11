#pragma once

#include <string>

#include "Stream.h"

struct retro_vfs_interface;

class CLibretroVfsStream final : public Framework::CStream
{
public:
	CLibretroVfsStream(retro_vfs_interface*, std::string);
	~CLibretroVfsStream() override;

	void Seek(int64, Framework::STREAM_SEEK_DIRECTION) override;
	uint64 Tell() override;
	uint64 Read(void*, uint64) override;
	uint64 Write(const void*, uint64) override;
	bool IsEOF() override;
	uint64 GetLength() override;

private:
	retro_vfs_interface* m_interface = nullptr;
	struct retro_vfs_file_handle* m_handle = nullptr;
	std::string m_path;
	bool m_isEof = false;
};
