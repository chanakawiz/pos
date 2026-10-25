import React from 'react';
import type { Category } from '../types/pos';
import { LayoutGrid, Coffee, Smartphone, ShoppingBag, Sparkles, Footprints, Layers } from 'lucide-react';

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
  const getCategoryIcon = (name: string) => {
    const text = name.toLowerCase();
    if (text.includes('smart') || text.includes('tech') || text.includes('phone') || text.includes('mobile')) {
      return <Smartphone className="w-4 h-4" />;
    }
    if (text.includes('fashion') || text.includes('apparel') || text.includes('clothing')) {
      return <ShoppingBag className="w-4 h-4" />;
    }
    if (text.includes('footwear') || text.includes('shoe') || text.includes('sneaker')) {
      return <Footprints className="w-4 h-4" />;
    }
    if (text.includes('perfume') || text.includes('cosmetic') || text.includes('beauty')) {
      return <Sparkles className="w-4 h-4" />;
    }
    if (text.includes('food') || text.includes('beverage') || text.includes('drink') || text.includes('coffee')) {
      return <Coffee className="w-4 h-4" />;
    }
    return <Layers className="w-4 h-4" />;
  };

  return (
    <div className="flex items-center gap-2 overflow-x-auto py-2.5 px-6 bg-slate-900/60 border-b border-slate-800/80 no-scrollbar select-none shrink-0">
      <button
        type="button"
        onClick={() => onSelectCategory(null)}
        className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all duration-150 cursor-pointer ${
          selectedCategoryUuid === null
            ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/30 scale-[1.02]'
            : 'bg-slate-800/80 text-slate-300 hover:bg-slate-700/80 hover:text-white border border-slate-700/60'
        }`}
      >
        <LayoutGrid className="w-4 h-4" />
        <span>All Items</span>
      </button>

      {categories.map((category) => {
        const isSelected = selectedCategoryUuid === category.uuid;
        return (
          <button
            key={category.uuid}
            type="button"
            onClick={() => onSelectCategory(category.uuid)}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all duration-150 cursor-pointer ${
              isSelected
                ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/30 scale-[1.02]'
                : 'bg-slate-800/80 text-slate-300 hover:bg-slate-700/80 hover:text-white border border-slate-700/60'
            }`}
          >
            {getCategoryIcon(category.name)}
            <span>{category.name}</span>
          </button>
        );
      })}
    </div>
  );
};

