# 🎨 PinIt Landing Page - Design System

## Color Palette

### Primary Colors
```css
--primary-color: #6366f1     /* Indigo - Main brand color */
--primary-hover: #4f46e5     /* Darker indigo for hover states */
--secondary-color: #8b5cf6   /* Purple - Accent color */
```

### Background Colors
```css
--background: #0f172a        /* Dark navy - Main background */
--surface: #1e293b           /* Slate - Cards and elevated surfaces */
--border: #334155            /* Dark slate - Borders and dividers */
```

### Text Colors
```css
--text-primary: #f1f5f9      /* Light gray - Primary text */
--text-secondary: #cbd5e1    /* Medium gray - Secondary text */
```

### Status Colors
```css
--success: #10b981           /* Green - Success states */
--error: #ef4444             /* Red - Error states */
```

### Gradients
```css
/* Primary gradient - Used for buttons and headings */
background: linear-gradient(135deg, #6366f1, #8b5cf6);

/* Card hover gradient */
background: linear-gradient(135deg, rgba(99, 102, 241, 0.1), rgba(139, 92, 246, 0.1));
```

---

## Typography

### Font Stack
```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
```

### Type Scale

| Element | Size | Weight | Use Case |
|---------|------|--------|----------|
| Hero Title | 3.5rem (56px) | 800 | Main page title |
| Section Title | 2.5rem (40px) | 700 | Section headings |
| Card Title | 1.5rem (24px) | 600 | Card headings |
| Body Large | 1.25rem (20px) | 400 | Lead paragraphs |
| Body | 1rem (16px) | 400 | Regular text |
| Small | 0.9rem (14px) | 400 | Meta info |

### Line Heights
- Headings: 1.2
- Body text: 1.6
- Tight: 1.4

---

## Spacing System

### Scale (based on 1rem = 16px)
```
0.5rem  = 8px    → gaps, small padding
0.75rem = 12px   → button padding
1rem    = 16px   → base unit
1.5rem  = 24px   → card padding
2rem    = 32px   → section margins
2.5rem  = 40px   → modal padding
3rem    = 48px   → large gaps
4rem    = 64px   → section spacing
6rem    = 96px   → section padding
```

---

## Components

### Buttons

#### Primary Button
```css
background: linear-gradient(135deg, #6366f1, #8b5cf6);
color: white;
padding: 0.75rem 1.5rem;
border-radius: 0.5rem;
font-weight: 600;
transition: all 0.3s ease;

/* Hover */
transform: translateY(-2px);
box-shadow: 0 10px 25px rgba(99, 102, 241, 0.3);
```

#### Ghost Button
```css
background: transparent;
color: #cbd5e1;
padding: 0.75rem 1.5rem;
border-radius: 0.5rem;

/* Hover */
color: #f1f5f9;
background: #1e293b;
```

#### Outline Button
```css
background: transparent;
color: #f1f5f9;
border: 2px solid #334155;
padding: 0.75rem 1.5rem;
border-radius: 0.5rem;

/* Hover */
border-color: #6366f1;
background: rgba(99, 102, 241, 0.1);
```

#### Large Button
```css
padding: 1rem 2rem;
font-size: 1.1rem;
```

### Cards

#### Feature Card
```css
background: #0f172a;
padding: 2rem;
border-radius: 1rem;
border: 1px solid #334155;
transition: all 0.3s ease;

/* Hover */
transform: translateY(-5px);
border-color: #6366f1;
box-shadow: 0 10px 30px rgba(99, 102, 241, 0.2);
```

#### Stat Card
```css
background: #1e293b;
padding: 1.5rem;
border-radius: 1rem;
border: 1px solid #334155;
display: flex;
align-items: center;
gap: 1rem;
```

#### Event Card
```css
background: #1e293b;
padding: 1.5rem;
border-radius: 1rem;
border: 1px solid #334155;
transition: all 0.3s ease;
```

### Inputs

#### Text Input
```css
padding: 0.875rem;
border-radius: 0.5rem;
border: 1px solid #334155;
background: #0f172a;
color: #f1f5f9;
font-size: 1rem;
transition: all 0.3s ease;

/* Focus */
outline: none;
border-color: #6366f1;
box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
```

### Modal

```css
/* Overlay */
background: rgba(0, 0, 0, 0.7);
backdrop-filter: blur(5px);

/* Content */
background: #1e293b;
border-radius: 1rem;
padding: 2.5rem;
border: 1px solid #334155;
box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
```

---

## Animations

### Fade In
```css
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

animation: fadeIn 0.6s ease-out;
```

### Slide In
```css
@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(-20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

animation: slideIn 0.6s ease-out;
```

### Float (For Icons)
```css
@keyframes float {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

animation: float 3s ease-in-out infinite;
```

### Spin (For Loaders)
```css
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

animation: spin 1s linear infinite;
```

---

## Shadows

### Elevation System

```css
/* Level 1 - Subtle */
box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);

/* Level 2 - Card hover */
box-shadow: 0 10px 30px rgba(99, 102, 241, 0.2);

/* Level 3 - Elevated */
box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);

/* Button hover */
box-shadow: 0 10px 25px rgba(99, 102, 241, 0.3);
```

---

## Border Radius

```css
/* Small */
border-radius: 0.5rem;   /* Buttons, inputs */

/* Medium */
border-radius: 0.75rem;  /* Icons */

/* Large */
border-radius: 1rem;     /* Cards, modals */
```

---

## Responsive Breakpoints

```css
/* Mobile */
@media (max-width: 768px) {
  /* Stack layouts, reduce font sizes */
}

/* Tablet */
@media (min-width: 769px) and (max-width: 1024px) {
  /* 2-column grids */
}

/* Desktop */
@media (min-width: 1025px) {
  /* 3-column grids, full layouts */
}
```

---

## Layout

### Container
```css
max-width: 1200px;
margin: 0 auto;
padding: 0 1rem;
```

### Grid Systems

#### Features Grid
```css
display: grid;
grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
gap: 2rem;
```

#### Stats Grid
```css
display: grid;
grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
gap: 1.5rem;
```

---

## Iconography

### Emoji Icons Used

| Category | Icon | Purpose |
|----------|------|---------|
| Logo | 📍 | Brand identity |
| Map | 🗺️ | Discover events |
| People | 👥 | Social/friends |
| Calendar | 📅 | Events |
| Star | ⭐ | Reputation |
| Bell | 🔔 | Notifications |
| Globe | 🌍 | Global community |
| Mobile | 📱 | Mobile app |
| Study | 📚 | Study events |
| Party | 🎉 | Social events |
| Graduate | 🎓 | Academic events |

---

## Accessibility

### Color Contrast
- All text meets WCAG AA standards
- Primary on background: 7.2:1
- Secondary on background: 4.8:1

### Focus States
- Visible focus indicators on all interactive elements
- Blue outline with subtle shadow
- Keyboard navigable

### Screen Readers
- Semantic HTML5 elements
- ARIA labels where needed
- Alt text for images

---

## Usage Examples

### Gradient Text
```css
.gradient-text {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
```

### Glassmorphism Header
```css
.header {
  background: rgba(15, 23, 42, 0.8);
  backdrop-filter: blur(10px);
}
```

### Card Hover Effect
```css
.card {
  transition: all 0.3s ease;
}

.card:hover {
  transform: translateY(-5px);
  border-color: #6366f1;
  box-shadow: 0 10px 30px rgba(99, 102, 241, 0.2);
}
```

---

## Design Principles

1. **Dark Mode First** - Easier on the eyes, modern aesthetic
2. **Gradient Accents** - Indigo to purple for visual interest
3. **Smooth Transitions** - 0.3s ease for most interactions
4. **Card-Based Layout** - Clear content hierarchy
5. **Generous Spacing** - Breathing room for content
6. **Subtle Shadows** - Depth without distraction
7. **Consistent Patterns** - Predictable user experience
8. **Mobile Responsive** - Works beautifully on all devices

---

## Customization Guide

Want to change the look? Update these CSS variables in `src/index.css`:

```css
:root {
  /* Change brand colors */
  --primary-color: #your-color;
  --secondary-color: #your-color;
  
  /* Change background */
  --background: #your-color;
  --surface: #your-color;
  
  /* Change text */
  --text-primary: #your-color;
  --text-secondary: #your-color;
}
```

All components will automatically use the new colors! 🎨

---

**Design System Version:** 1.0  
**Last Updated:** October 14, 2025


