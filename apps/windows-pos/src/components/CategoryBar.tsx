import React from 'react';
import type { Category } from '../types/pos';
import { LayoutGrid, Coffee, Cookie, Milk, Sandwich, Sparkles } from 'lucide-react';

interface Props {
  categories: Category[];
  selectedCategoryUuid: string | null;
  onSelectCategory: (uuid: string | null) => void;
}

export const CategoryBar: React.FC<Props> = ({
  categories,
  selectedCategoryUuid,
  onSelectCategory,
}) => {
  const getIcon = (name: string) => {
    const lower = name.toLowerCase();
    if (lower.includes('bev') || lower.includes('coffee') || lower.includes('tea')) return <Coffee className="w-4 h-4" />;
    if (lower.includes('snack') || lower.includes('chip')) return <Cookie className="w-4 h-4" />;
    if (lower.includes('dairy') || lower.includes('egg')) return <Milk className="w-4 h-4" />;
    if (lower.includes('bake') || lower.includes('bread')) return <Sandwich className="w-4 h-4" />;
    return <Sparkles className="w-4 h-4" />;
  };

  return (
    <div className="flex items-center gap-2 overflow-x-auto py-3 px-6 bg-slate-900/50 border-b border-slate-800 no-scrollbar">
      <button
        onClick={() => onSelectCategory(null)}
        className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all duration-200 cursor-pointer ${
          selectedCategoryUuid === null
            ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/30 scale-[1.02]'
            : 'bg-slate-800/80 text-slate-300 hover:bg-slate-700/80 hover:text-white border border-slate-700/50'
        }`}
      >
        <LayoutGrid className="w-4 h-4" />
        <span>All Items</span>
      </button>

      {categories.map((cat) => {
        const isSelected = selectedCategoryUuid === cat.uuid;
        return (
          <button
            key={cat.uuid}
            onClick={() => onSelectCategory(cat.uuid)}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all duration-200 cursor-pointer ${
              isSelected
                ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/30 scale-[1.02]'
                : 'bg-slate-800/80 text-slate-300 hover:bg-slate-700/80 hover:text-white border border-slate-700/50'
            }`}
          >
            {getIcon(cat.name)}
            <span>{cat.name}</span>
          </button>
        );
      })}
    </div>
  );
};
