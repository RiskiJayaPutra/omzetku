<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'nama_lengkap' => 'required|string|min:3|max:255',
            'nama_usaha' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'nomor_telepon' => 'required|string|min:10|max:20',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $user = User::create([
            'nama_lengkap' => $request->nama_lengkap,
            'nama_usaha' => $request->nama_usaha,
            'email' => $request->email,
            'nomor_telepon' => $request->nomor_telepon,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil',
            'data' => [
                'user' => $user,
                'access_token' => $token,
                'token_type' => 'Bearer',
            ]
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password salah.'],
            ]);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'data' => [
                'user' => $user,
                'access_token' => $token,
                'token_type' => 'Bearer',
            ]
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil'
        ]);
    }

    public function user(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $request->user()
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'nama_lengkap' => 'sometimes|required|string|min:3|max:255',
            'nama_usaha' => 'sometimes|required|string|max:255',
            'nomor_telepon' => 'sometimes|required|string|min:10|max:20',
            'photo' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        // Update text fields
        if ($request->has('nama_lengkap')) {
            $user->nama_lengkap = $request->nama_lengkap;
        }
        if ($request->has('nama_usaha')) {
            $user->nama_usaha = $request->nama_usaha;
        }
        if ($request->has('nomor_telepon')) {
            $user->nomor_telepon = $request->nomor_telepon;
        }

        // Handle photo upload
        if ($request->hasFile('photo')) {
            $photo = $request->file('photo');
            Log::info('Photo upload received', [
                'original_name' => $photo->getClientOriginalName(),
                'size' => $photo->getSize(),
                'mime_type' => $photo->getMimeType()
            ]);
            
            $photoName = time() . '_' . $user->id . '.' . $photo->getClientOriginalExtension();
            $uploadPath = public_path('uploads/profiles');
            
            // Move file and verify
            $photo->move($uploadPath, $photoName);
            $fullPath = $uploadPath . '/' . $photoName;
            
            if (!file_exists($fullPath)) {
                Log::error('Photo file not found after upload', ['path' => $fullPath]);
                return response()->json([
                    'success' => false,
                    'message' => 'Gagal menyimpan foto'
                ], 500);
            }
            
            Log::info('Photo saved and verified', ['path' => 'uploads/profiles/' . $photoName]);
            
            // Delete old photo if exists
            if ($user->photo_url) {
                $oldPhotoPath = public_path($user->photo_url);
                if (file_exists($oldPhotoPath)) {
                    unlink($oldPhotoPath);
                    Log::info('Old photo deleted', ['path' => $user->photo_url]);
                }
            }
            
            $user->photo_url = 'uploads/profiles/' . $photoName;
        } else {
            Log::info('No photo file received in request');
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui',
            'data' => $user
        ]);
    }
}