<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Gallery;

class GalleryController extends Controller
{
    public function index()
    {
        $galleries = Gallery::latest()->get();
        return view('admin.galleries.index', compact('galleries'));
    }

    public function create()
    {
        return view('admin.galleries.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:2048',
            'description' => 'nullable'
        ]);

        $imagePath = $request->file('image')->store('galleries', 'public');

        Gallery::create([
            'user_id' => auth()->id(),
            'image' => $imagePath,
            'description' => $request->description
        ]);

        return redirect()->route('galleries.index')->with('success', 'Gallery added');
    }

    public function edit($id)
    {
        $gallery = Gallery::findOrFail($id);
        return view('admin.galleries.edit', compact('gallery'));
    }

    public function update(Request $request, $id)
    {
        $gallery = Gallery::findOrFail($id);

        $request->validate([
            'image' => 'nullable|image|max:2048'
        ]);

        $imagePath = $gallery->image;

        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('galleries', 'public');
        }

        $gallery->update([
            'image' => $imagePath,
            'description' => $request->description
        ]);

        return redirect()->route('galleries.index')->with('success', 'Gallery updated');
    }

    public function destroy($id)
    {
        Gallery::findOrFail($id)->delete();
        return back()->with('success', 'Gallery deleted');
    }
}
