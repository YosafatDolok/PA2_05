<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Menu;
use App\Models\MenuCategory;

class MenuController extends Controller
{
    public function index()
    {
        $menus = Menu::with('category', 'user')->latest()->get();
        return view('admin.menus.index', compact('menus'));
    }

    public function create()
    {
        $categories = MenuCategory::all();
        return view('admin.menus.create', compact('categories'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'category_id' => 'required|exists:menu_categories,category_id',
            'description' => 'nullable',
            'image' => 'nullable|image|max:2048'
        ]);

        try {
            $imagePath = null;

            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('menus', 'public');
            }

            Menu::create([
                'name' => $request->name,
                'category_id' => $request->category_id,
                'description' => $request->description,
                'image' => $imagePath,
                'user_id' => auth()->id(),
                'available' => true
            ]);

            return redirect()->route('menus.index')
                ->with('success', 'Menu created successfully');

        } catch (\Exception $e) {
            return back()->with('error', 'Failed to create menu');
        }
    }

    public function edit($id)
    {
        $menu = Menu::findOrFail($id);
        $categories = MenuCategory::all();

        return view('admin.menus.edit', compact('menu', 'categories'));
    }

    public function update(Request $request, $id)
    {
        $menu = Menu::findOrFail($id);

        $request->validate([
            'name' => 'required',
            'category_id' => 'required|exists:menu_categories,category_id',
            'description' => 'nullable',
            'image' => 'nullable|image|max:2048'
        ]);

        try {
            $imagePath = $menu->image;

            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('menus', 'public');
            }

            $menu->update([
                'name' => $request->name,
                'category_id' => $request->category_id,
                'description' => $request->description,
                'image' => $imagePath,
                'available' => $request->has('available')
            ]);

            return redirect()->route('menus.index')
                ->with('success', 'Menu updated successfully');

        } catch (\Exception $e) {
            return back()->with('error', 'Failed to update menu');
        }
    }

    public function destroy($id)
    {
        try {
            Menu::findOrFail($id)->delete();

            return redirect()->route('menus.index')
                ->with('success', 'Menu deleted successfully');

        } catch (\Exception $e) {
            return redirect()->route('menus.index')
                ->with('error', 'Failed to delete menu');
        }
    }

    // Mobile API

    public function apiIndex()
    {
        $menus = Menu::with('category')
            ->where('available', true)
            ->get();

        return response()->json($menus);
    }

    public function apiShow($id)
    {
        $menu = Menu::with('category')->findOrFail($id);
        return response()->json($menu);
    }
}