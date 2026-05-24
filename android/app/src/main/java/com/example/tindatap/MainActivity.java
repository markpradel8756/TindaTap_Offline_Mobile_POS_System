package com.example.tindatap;

import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Map;

public class MainActivity extends FlutterActivity {
	private static final String CHANNEL = "tindatap/saf_backup";
	private static final int REQUEST_EXPORT_BACKUP = 9001;
	private static final int REQUEST_IMPORT_BACKUP = 9002;

	private MethodChannel.Result pendingResult;
	private byte[] pendingExportData;

	@Override
	public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
		super.configureFlutterEngine(flutterEngine);
		new MethodChannel(
				flutterEngine.getDartExecutor().getBinaryMessenger(),
				CHANNEL)
			.setMethodCallHandler(this::handleMethodCall);
	}

	private void handleMethodCall(MethodCall call, MethodChannel.Result result) {
		switch (call.method) {
			case "exportBackup":
				handleExportBackup(call, result);
				break;
			case "importBackup":
				handleImportBackup(result);
				break;
			default:
				result.notImplemented();
				break;
		}
	}

	private void handleExportBackup(MethodCall call, MethodChannel.Result result) {
		if (pendingResult != null) {
			result.error("busy", "Another file operation is already running.", null);
			return;
		}

		@SuppressWarnings("unchecked")
		Map<String, Object> args = call.arguments();
		if (args == null) {
			result.error("invalid_args", "Missing export arguments.", null);
			return;
		}

		Object data = args.get("data");
		if (!(data instanceof byte[])) {
			result.error("invalid_data", "Backup data was not provided.", null);
			return;
		}

		pendingExportData = (byte[]) data;
		String fileName = String.valueOf(args.getOrDefault("fileName", "tindatap_backup.json"));
		String mimeType = String.valueOf(args.getOrDefault("mimeType", "application/json"));
		pendingResult = result;

		Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
		intent.addCategory(Intent.CATEGORY_OPENABLE);
		intent.setType(mimeType);
		intent.putExtra(Intent.EXTRA_TITLE, fileName);
		intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
		startActivityForResult(intent, REQUEST_EXPORT_BACKUP);
	}

	private void handleImportBackup(MethodChannel.Result result) {
		if (pendingResult != null) {
			result.error("busy", "Another file operation is already running.", null);
			return;
		}

		pendingResult = result;
		Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
		intent.addCategory(Intent.CATEGORY_OPENABLE);
		intent.setType("application/json");
		intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
		intent.addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
		startActivityForResult(intent, REQUEST_IMPORT_BACKUP);
	}

	@Override
	@SuppressWarnings("deprecation")
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);

		if (requestCode == REQUEST_EXPORT_BACKUP) {
			MethodChannel.Result result = pendingResult;
			pendingResult = null;

			if (result == null) {
				clearExportState();
				return;
			}

			if (resultCode != RESULT_OK || data == null || data.getData() == null) {
				clearExportState();
				result.success(false);
				return;
			}

			Uri uri = data.getData();
			try (OutputStream outputStream = getContentResolver().openOutputStream(uri, "w")) {
				if (outputStream == null) {
					throw new IOException("Unable to open the selected save location.");
				}
				outputStream.write(pendingExportData == null ? new byte[0] : pendingExportData);
				outputStream.flush();
				result.success(true);
			} catch (Exception e) {
				result.error("export_failed", e.getMessage(), null);
			} finally {
				clearExportState();
			}
			return;
		}

		if (requestCode == REQUEST_IMPORT_BACKUP) {
			MethodChannel.Result result = pendingResult;
			pendingResult = null;

			if (result == null) {
				return;
			}

			if (resultCode != RESULT_OK || data == null || data.getData() == null) {
				result.success(null);
				return;
			}

			Uri uri = data.getData();
			try {
				final int takeFlags = data.getFlags() &
					(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
				try {
					getContentResolver().takePersistableUriPermission(uri, takeFlags);
				} catch (SecurityException ignored) {
					// Some document providers do not grant persistable permissions.
				}

				byte[] bytes;
				try (InputStream inputStream = getContentResolver().openInputStream(uri)) {
					if (inputStream == null) {
						throw new IOException("Unable to open the selected backup file.");
					}
					bytes = readAllBytes(inputStream);
				}
				result.success(bytes);
			} catch (Exception e) {
				result.error("import_failed", e.getMessage(), null);
			}
			return;
		}
	}

	private void clearExportState() {
		pendingExportData = null;
	}

	private byte[] readAllBytes(InputStream inputStream) throws IOException {
		ByteArrayOutputStream buffer = new ByteArrayOutputStream();
		byte[] chunk = new byte[8 * 1024];
		int read;
		while ((read = inputStream.read(chunk)) != -1) {
			buffer.write(chunk, 0, read);
		}
		return buffer.toByteArray();
	}
}
