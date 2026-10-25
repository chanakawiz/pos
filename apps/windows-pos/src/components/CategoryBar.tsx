import { Boxes, Check, ChevronRight, Diamond, HelpCircle, LayoutGrid } from 'lucide-react';
import type { Category } from '../types/pos';
import { usePosStore } from '../stores/usePosStore';
import { useAuthStore } from '../stores/useAuthStore';

interface Props {
  categories: Category[];
  selectedCategoryUuid: string | null;
  onSelectCategory: (uuid: string | null) => void;
}

export function CategoryBar({ categories, selectedCategoryUuid, onSelectCategory }: Props) {
  const { language, setLanguage, openModal } = usePosStore();
  const store = useAuthStore((state) => state.user?.store);
  return (
    <aside className="catalog-sidebar" aria-label="Catalog filters and tools">
      <div className="sidebar-store"><span className="eyebrow">YOUR WORKSPACE</span><div><Diamond /><strong>{store?.name || 'Your store'}</strong></div><small>{store?.currency_code || 'Store currency'}<span>Retail station</span></small></div>
      <div className="sidebar-heading"><h2>Categories</h2><span>{categories.length}</span></div>
      <nav className="category-list" aria-label="Product categories">
        <button type="button" aria-pressed={selectedCategoryUuid === null} className={selectedCategoryUuid === null ? 'is-active' : ''} onClick={() => onSelectCategory(null)}><LayoutGrid /><span>All Items</span><ChevronRight /></button>
        {categories.map((category) => <button type="button" key={category.uuid} aria-pressed={selectedCategoryUuid === category.uuid} className={selectedCategoryUuid === category.uuid ? 'is-active' : ''} onClick={() => onSelectCategory(category.uuid)}><Boxes /><span>{category.name}</span>{selectedCategoryUuid === category.uuid && <Check />}</button>)}
      </nav>
      <div className="sidebar-bottom">
        <span className="eyebrow">DISPLAY MODE</span>
        <div className="language-switch" aria-label="Display mode">{([
          ['en', 'EN', 'Language: English'],
          ['bilingual', 'Dual', 'Language: Dual (EN+සිං)'],
          ['si', 'සිං', 'Language: Sinhala (සිංහල)'],
        ] as const).map(([value, label, title]) => <button type="button" key={value} title={title} aria-pressed={language === value} className={language === value ? 'is-active' : ''} onClick={() => setLanguage(value)}>{label}</button>)}</div>
        <button type="button" className="sidebar-help" onClick={() => openModal('help')}><HelpCircle /><span>Help (F1)</span><kbd>F1</kbd></button>
        <p className="sidebar-footnote">A little more order.<br />A better day in store.</p>
      </div>
    </aside>
  );
}
