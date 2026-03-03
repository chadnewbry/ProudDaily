#!/usr/bin/env python3
"""Generate polished App Store screenshots for Proud Daily - v2."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os, random

REPO_DIR = "/Users/chadnewbry/dev/ProudDaily/screenshots"
OUTPUT_DIR = os.path.join(REPO_DIR, "store")

DEVICES = {
    "iPhone_6.7": (1290, 2796),
    "iPhone_6.5": (1242, 2688),
    "iPhone_5.5": (1242, 2208),
    "iPad_12.9":  (2048, 2732),
}

RAINBOW = ["#E40303", "#FF8C00", "#FFED00", "#008026", "#004DFF", "#750787"]
TRANS = ["#5BCEFA", "#F5A9B8", "#FFFFFF", "#F5A9B8", "#5BCEFA"]
BISEXUAL = ["#D60270", "#9B4F96", "#0038A8"]
PANSEXUAL = ["#FF218C", "#FFD800", "#21B1FF"]
NONBINARY = ["#FCF434", "#FFFFFF", "#9C59D1", "#2C2C2C"]
LESBIAN = ["#D52D00", "#FF9A56", "#FFFFFF", "#D462A6", "#A30262"]
OCEAN = ["#1AB3A5", "#268CCC", "#4073B3", "#59BFA5"]
PASTEL = ["#FFB3BA", "#FFDFBA", "#FFFFBA", "#BAFFC9", "#BAE1FF", "#D4BAFF"]
SUNSET = ["#FF6B35", "#F7931E", "#FFD700", "#FF4500"]
ASEXUAL = ["#000000", "#A3A3A3", "#FFFFFF", "#800080"]

FB = "/Library/Fonts/SF-Pro-Display-Bold.otf"
FH = "/Library/Fonts/SF-Pro-Display-Heavy.otf"
FM = "/Library/Fonts/SF-Pro-Display-Medium.otf"
FL = "/Library/Fonts/SF-Pro-Display-Light.otf"
FR = "/Library/Fonts/SF-Compact-Rounded-Bold.otf"
FRM = "/Library/Fonts/SF-Compact-Rounded-Medium.otf"

def hex_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def vgrad(draw, w, h, colors, y0=0, y1=None):
    if y1 is None: y1 = h
    rgbs = [hex_rgb(c) for c in colors]
    total = max(y1 - y0, 1)
    seg = total / max(len(rgbs) - 1, 1)
    for y in range(y0, y1):
        idx = min(int((y - y0) / seg), len(rgbs) - 2)
        t = ((y - y0) - idx * seg) / seg
        r = int(rgbs[idx][0]*(1-t) + rgbs[idx+1][0]*t)
        g = int(rgbs[idx][1]*(1-t) + rgbs[idx+1][1]*t)
        b = int(rgbs[idx][2]*(1-t) + rgbs[idx+1][2]*t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

def vgrad_on(img, colors, x0, y0, x1, y1):
    """Draw gradient on a specific region of image."""
    rgbs = [hex_rgb(c) for c in colors]
    draw = ImageDraw.Draw(img)
    total = max(y1 - y0, 1)
    seg = total / max(len(rgbs)-1, 1)
    for y in range(y0, y1):
        idx = min(int((y-y0)/seg), len(rgbs)-2)
        t = ((y-y0)-idx*seg)/seg
        r = int(rgbs[idx][0]*(1-t)+rgbs[idx+1][0]*t)
        g = int(rgbs[idx][1]*(1-t)+rgbs[idx+1][1]*t)
        b = int(rgbs[idx][2]*(1-t)+rgbs[idx+1][2]*t)
        draw.line([(x0,y),(x1,y)], fill=(r,g,b))

def ctxt(draw, text, y, w, fnt, fill=(255,255,255)):
    bb = draw.textbbox((0,0), text, font=fnt)
    draw.text(((w-(bb[2]-bb[0]))//2, y), text, font=fnt, fill=fill)

def F(path, size):
    try: return ImageFont.truetype(path, size)
    except: return ImageFont.load_default()

def rainbow_text(img, text, y, fnt):
    d = ImageDraw.Draw(img)
    w = img.size[0]
    bb = d.textbbox((0,0), text, font=fnt)
    tw = bb[2]-bb[0]
    x0 = (w-tw)//2
    rgbs = [hex_rgb(c) for c in RAINBOW]
    cx = x0
    for ch in text:
        pos = (cx-x0)/max(tw,1)
        idx = min(int(pos*(len(rgbs)-1)), len(rgbs)-2)
        t = pos*(len(rgbs)-1)-idx
        r = int(rgbs[idx][0]*(1-t)+rgbs[idx+1][0]*t)
        g = int(rgbs[idx][1]*(1-t)+rgbs[idx+1][1]*t)
        b = int(rgbs[idx][2]*(1-t)+rgbs[idx+1][2]*t)
        d.text((cx,y), ch, font=fnt, fill=(r,g,b))
        cx += int(d.textlength(ch, font=fnt))

def draw_phone(draw, px, py, pw, ph, bezel=14, corner=55):
    """Draw realistic phone frame with notch."""
    # Outer bezel
    draw.rounded_rectangle([px-bezel, py-bezel, px+pw+bezel, py+ph+bezel],
                          radius=corner, fill=(25,25,25))
    # Subtle highlight on top edge
    draw.rounded_rectangle([px-bezel+2, py-bezel+2, px+pw+bezel-2, py+ph+bezel-2],
                          radius=corner-1, outline=(50,50,50), width=1)

def smask(pw, ph, r=48):
    m = Image.new("L", (pw, ph), 0)
    ImageDraw.Draw(m).rounded_rectangle([0,0,pw-1,ph-1], radius=r, fill=255)
    return m

def draw_status_bar(sd, pw):
    """Draw realistic iOS status bar."""
    sf = F(FM, int(pw*0.038))
    ssf = F(FM, int(pw*0.032))
    # Time
    sd.text((int(pw*0.07), int(pw*0.02)), "9:41", font=sf, fill=(255,255,255))
    # Right side indicators
    rx = pw - int(pw*0.07)
    # Battery
    bw, bh = int(pw*0.06), int(pw*0.028)
    by = int(pw*0.025)
    sd.rounded_rectangle([rx-bw, by, rx, by+bh], radius=3, outline=(255,255,255), width=2)
    sd.rectangle([rx, by+bh//4, rx+3, by+bh*3//4], fill=(255,255,255))
    sd.rectangle([rx-bw+3, by+3, rx-3, by+bh-3], fill=(76,217,100))
    # Signal bars
    sx = rx - bw - int(pw*0.06)
    for i in range(4):
        bh2 = int(pw*0.008)*(i+1)+4
        sd.rectangle([sx+i*7, by+bh-bh2, sx+i*7+4, by+bh], fill=(255,255,255))
    # WiFi
    wx = sx - int(pw*0.05)
    sd.arc([wx-8, by, wx+8, by+12], 200, 340, fill=(255,255,255), width=2)
    sd.arc([wx-5, by+4, wx+5, by+10], 200, 340, fill=(255,255,255), width=2)
    sd.ellipse([wx-2, by+8, wx+2, by+12], fill=(255,255,255))
    # Dynamic Island
    diw, dih = int(pw*0.25), int(pw*0.045)
    dix = (pw-diw)//2
    sd.rounded_rectangle([dix, int(pw*0.015), dix+diw, int(pw*0.015)+dih], radius=dih//2, fill=(0,0,0))

def draw_tab_bar(sd, pw, ph, active=0):
    th = int(ph*0.08)
    # Frosted bg
    sd.rectangle([0, ph-th, pw, ph], fill=(15,15,28,240))
    sd.line([(0,ph-th),(pw,ph-th)], fill=(50,50,70), width=1)
    labels = ["Home","Library","Progress","Journal"]
    icons = ["🏠","📚","📊","📓"]
    tw = pw//4
    lf = F(FM, int(pw*0.024))
    if_ = F(FM, int(pw*0.045))
    for i, (l, ic) in enumerate(zip(labels, icons)):
        cx = i*tw+tw//2
        active_color = hex_rgb("#E40303") if active==0 else hex_rgb("#5BCEFA") if active==1 else hex_rgb("#9B4F96")
        c = active_color if i==active else (90,90,120)
        # Icon (simple circle as placeholder)
        r = int(pw*0.022)
        iy = ph-th+int(th*0.15)
        if i == active:
            sd.ellipse([cx-r, iy, cx+r, iy+r*2], fill=c)
        else:
            sd.ellipse([cx-r, iy, cx+r, iy+r*2], outline=c, width=2)
        bb = sd.textbbox((0,0), l, font=lf)
        sd.text((cx-(bb[2]-bb[0])//2, iy+r*2+4), l, font=lf, fill=c)

def draw_home_indicator(sd, pw, ph):
    """iOS home indicator bar."""
    bw = int(pw*0.35)
    sd.rounded_rectangle([(pw-bw)//2, ph-int(ph*0.015), (pw+bw)//2, ph-int(ph*0.008)],
                         radius=3, fill=(255,255,255,80))

# ━━━ Content functions ━━━
# Phone takes ~80% of width, positioned to crop bottom slightly for drama

def phone_dims(w, h):
    """Return phone dimensions scaled to screenshot size - bigger, more prominent."""
    pw = int(w * 0.82)
    ph = int(pw * 2.17)  # iPhone aspect ratio ~1:2.17
    px = (w - pw) // 2
    py = int(h * 0.20)  # phone extends below canvas for dramatic crop
    return px, py, pw, ph

def c_home(img, draw, w, h):
    px, py, pw, ph = phone_dims(w, h)
    draw_phone(draw, px, py, pw, min(ph, h-py+int(ph*0.05)))
    mk = smask(pw, ph)
    s = Image.new("RGBA", (pw, ph), (14,14,26,255))
    sd = ImageDraw.Draw(s)
    draw_status_bar(sd, pw)
    draw_tab_bar(sd, pw, ph, 0)
    draw_home_indicator(sd, pw, ph)

    # Affirmation card - large, prominent
    m = int(pw*0.06); ct = int(ph*0.06); cb = int(ph*0.68)
    cw, ch_ = pw-2*m, cb-ct
    card = Image.new("RGBA", (cw, ch_)); cd = ImageDraw.Draw(card)
    vgrad(cd, cw, ch_, RAINBOW)
    # Subtle overlay pattern
    for i in range(0, cw, 40):
        cd.line([(i, 0), (i+ch_, ch_)], fill=(255,255,255,8), width=1)
    cm = Image.new("L", (cw, ch_), 0)
    ImageDraw.Draw(cm).rounded_rectangle([0,0,cw-1,ch_-1], radius=32, fill=255)
    s.paste(card, (m, ct), cm)

    # Category pill
    sf = F(FM, int(pw*0.028))
    pill_text = "Self-Love"
    pbb = sd.textbbox((0,0), pill_text, font=sf)
    ppw = pbb[2]-pbb[0]+24; pph = pbb[3]-pbb[1]+14
    sd.rounded_rectangle([m+20, ct+20, m+20+ppw, ct+20+pph], radius=pph//2, fill=(255,255,255,40))
    sd.text((m+32, ct+24), pill_text, font=sf, fill=(255,255,255))

    # Affirmation text
    af = F(FR, int(pw*0.065))
    lines = ["I am worthy of", "love exactly", "as I am"]
    lh = int(pw*0.085)
    ty = ct + ch_//2 - len(lines)*lh//2
    for line in lines:
        bb = sd.textbbox((0,0), line, font=af)
        sd.text(((pw-(bb[2]-bb[0]))//2, ty), line, font=af, fill=(255,255,255))
        ty += lh

    # Streak badge at bottom of card
    badge_y = cb - 50
    badge_text = "🔥 7 day streak"
    bbb = sd.textbbox((0,0), badge_text, font=sf)
    bpw = bbb[2]-bbb[0]+20
    sd.rounded_rectangle([(pw-bpw)//2, badge_y, (pw+bpw)//2, badge_y+30], radius=15, fill=(0,0,0,60))
    ctxt(sd, badge_text, badge_y+4, pw, sf)

    # "Hold to reveal" with icon
    hint_f = F(FM, int(pw*0.032))
    hy = cb + int(pw*0.04)
    ctxt(sd, "👆 Hold to reveal your affirmation", hy, pw, hint_f, fill=(130,130,165))

    # Clip to visible area
    visible_h = min(ph, h - py + int(h*0.02))
    crop_mk = smask(pw, visible_h)
    vis = s.crop((0, 0, pw, visible_h))
    img.paste(vis, (px, py), crop_mk)

def c_hold(img, draw, w, h):
    px, py, pw, ph = phone_dims(w, h)
    draw_phone(draw, px, py, pw, min(ph, h-py+int(ph*0.05)))
    mk = smask(pw, ph)
    s = Image.new("RGBA", (pw, ph), (14,14,26,255))
    sd = ImageDraw.Draw(s)
    draw_status_bar(sd, pw)
    draw_tab_bar(sd, pw, ph, 0)
    draw_home_indicator(sd, pw, ph)

    m = int(pw*0.06); ct = int(ph*0.06); cb = int(ph*0.68)
    cw, ch_ = pw-2*m, cb-ct
    card = Image.new("RGBA", (cw, ch_)); cd = ImageDraw.Draw(card)
    vgrad(cd, cw, ch_, TRANS)
    # Top 60% blurred
    blur_h = int(ch_*0.55)
    top = card.crop((0,0,cw,blur_h)).filter(ImageFilter.GaussianBlur(30))
    card.paste(top, (0,0))
    cm = Image.new("L", (cw, ch_), 0)
    ImageDraw.Draw(cm).rounded_rectangle([0,0,cw-1,ch_-1], radius=32, fill=255)
    s.paste(card, (m, ct), cm)

    # Category pill
    sf = F(FM, int(pw*0.028))
    sd.rounded_rectangle([m+20, ct+20, m+130, ct+44], radius=12, fill=(255,255,255,40))
    sd.text((m+32, ct+24), "Identity", font=sf, fill=(255,255,255))

    # Revealed text in clear area
    af = F(FR, int(pw*0.06))
    lines = ["My identity is", "my superpower"]
    lh = int(pw*0.08)
    ty = ct + blur_h + int(ch_*0.08)
    for line in lines:
        bb = sd.textbbox((0,0), line, font=af)
        sd.text(((pw-(bb[2]-bb[0]))//2, ty), line, font=af, fill=(255,255,255))
        ty += lh

    # Touch ring indicator
    ring_cx, ring_cy = pw//2, ct + blur_h - 30
    ring_r = 50
    ov = Image.new("RGBA", (ring_r*2, ring_r*2), (0,0,0,0))
    ovd = ImageDraw.Draw(ov)
    ovd.ellipse([0,0,ring_r*2-1,ring_r*2-1], fill=(255,255,255,25))
    ovd.ellipse([10,10,ring_r*2-11,ring_r*2-11], fill=(255,255,255,15))
    s.paste(ov, (ring_cx-ring_r, ring_cy-ring_r), ov)

    # Progress ring
    pr_y = cb + int(pw*0.02)
    pr_r = 18
    sd.arc([pw//2-pr_r, pr_y, pw//2+pr_r, pr_y+pr_r*2], -90, 160, fill=(255,255,255), width=4)
    sd.ellipse([pw//2-3, pr_y-2, pw//2+3, pr_y+4], fill=(255,255,255))
    ctxt(sd, "65%", pr_y+pr_r*2+8, pw, F(FM, int(pw*0.028)), fill=(160,160,190))

    visible_h = min(ph, h-py+int(h*0.02))
    vis = s.crop((0,0,pw,visible_h))
    img.paste(vis, (px, py), smask(pw, visible_h))

def c_cats(img, draw, w, h):
    px, py, pw, ph = phone_dims(w, h)
    draw_phone(draw, px, py, pw, min(ph, h-py+int(ph*0.05)))
    mk = smask(pw, ph)
    s = Image.new("RGBA", (pw, ph), (14,14,26,255))
    sd = ImageDraw.Draw(s)
    draw_status_bar(sd, pw)
    draw_tab_bar(sd, pw, ph, 1)
    draw_home_indicator(sd, pw, ph)

    tf = F(FB, int(pw*0.065)); lf = F(FM, int(pw*0.03))
    sd.text((int(pw*0.06), int(ph*0.055)), "Library", font=tf, fill=(255,255,255))

    cats = [("Self-Love",RAINBOW,"💜"),("Coming Out",TRANS,"🌈"),("Resilience",BISEXUAL,"💪"),
            ("Community",LESBIAN,"🤝"),("Identity",PANSEXUAL,"✨"),("Body Positivity",NONBINARY,"🦋"),
            ("Relationships",OCEAN,"💕"),("Mindfulness",PASTEL,"🧘"),("Pride",SUNSET,"🏳️‍🌈")]
    
    cols = 3; mg = int(pw*0.05); gap = int(pw*0.03)
    tw_ = (pw-2*mg-(cols-1)*gap)//cols; th_ = int(tw_*1.1)
    sy = int(ph*0.10)
    
    for i, (name, colors, emoji) in enumerate(cats):
        col, row = i%cols, i//cols
        tx = mg + col*(tw_+gap); ty = sy + row*(th_+gap)
        tile = Image.new("RGBA", (tw_, th_)); td = ImageDraw.Draw(tile)
        vgrad(td, tw_, th_, colors)
        # Overlay pattern
        for k in range(0, tw_, 30):
            td.line([(k,0),(k+th_,th_)], fill=(255,255,255,10), width=1)
        tm = Image.new("L",(tw_,th_),0)
        ImageDraw.Draw(tm).rounded_rectangle([0,0,tw_-1,th_-1], radius=18, fill=255)
        s.paste(tile, (tx, ty), tm)
        # Name at bottom of tile
        nf = F(FM, int(pw*0.026))
        bb = sd.textbbox((0,0), name, font=nf)
        nw = bb[2]-bb[0]
        # Dark overlay at bottom
        sd.rounded_rectangle([tx, ty+th_-int(th_*0.35), tx+tw_, ty+th_],
                           radius=0, fill=(0,0,0,100))
        sd.text((tx+(tw_-nw)//2, ty+th_-int(th_*0.28)), name, font=nf, fill=(255,255,255))
        # Count
        cf = F(FL, int(pw*0.02))
        sd.text((tx+(tw_-nw)//2, ty+th_-int(th_*0.13)), "12 affirmations", font=cf, fill=(200,200,220))

    visible_h = min(ph, h-py+int(h*0.02))
    vis = s.crop((0,0,pw,visible_h))
    img.paste(vis, (px, py), smask(pw, visible_h))

def c_themes(img, draw, w, h):
    px, py, pw, ph = phone_dims(w, h)
    draw_phone(draw, px, py, pw, min(ph, h-py+int(ph*0.05)))
    s = Image.new("RGBA", (pw, ph), (14,14,26,255))
    sd = ImageDraw.Draw(s)
    draw_status_bar(sd, pw)

    tf = F(FB, int(pw*0.06)); sd.text((int(pw*0.06), int(ph*0.055)), "Choose Your Theme", font=tf, fill=(255,255,255))
    sf = F(FM, int(pw*0.03)); sd.text((int(pw*0.06), int(ph*0.055)+int(pw*0.07)), "Personalize your experience", font=sf, fill=(160,160,190))

    themes = [("Rainbow",RAINBOW),("Trans",TRANS),("Bisexual",BISEXUAL),("Pansexual",PANSEXUAL),
              ("Non-Binary",NONBINARY),("Lesbian",LESBIAN),("Asexual",ASEXUAL),
              ("Sunset",SUNSET),("Pastel",PASTEL),("Ocean",OCEAN)]
    
    cols = 2; mg = int(pw*0.05); gap = int(pw*0.035)
    tw_ = (pw-2*mg-gap)//cols; th_ = int(tw_*0.55)
    sy = int(ph*0.12); lf = F(FM, int(pw*0.028))
    
    for i, (name, colors) in enumerate(themes):
        col, row = i%cols, i//cols
        tx = mg + col*(tw_+gap); ty = sy + row*(th_+gap+int(pw*0.04))
        tile = Image.new("RGBA",(tw_,th_)); td = ImageDraw.Draw(tile)
        stripe = max(th_//len(colors),1)
        for j,c in enumerate(colors):
            td.rectangle([0,j*stripe,tw_,(j+1)*stripe+1],fill=hex_rgb(c))
        tm = Image.new("L",(tw_,th_),0)
        ImageDraw.Draw(tm).rounded_rectangle([0,0,tw_-1,th_-1],radius=16,fill=255)
        if i == 0:
            # Selected state - thicker white border + checkmark
            sd.rounded_rectangle([tx-4,ty-4,tx+tw_+4,ty+th_+4], radius=20, outline=(255,255,255), width=4)
        s.paste(tile,(tx,ty),tm)
        # Label
        bb = sd.textbbox((0,0),name,font=lf)
        sd.text((tx+(tw_-(bb[2]-bb[0]))//2, ty+th_+6), name, font=lf,
                fill=(255,255,255) if i==0 else (180,180,210))

    visible_h = min(ph, h-py+int(h*0.02))
    vis = s.crop((0,0,pw,visible_h))
    img.paste(vis, (px, py), smask(pw, visible_h))

def c_widgets(img, draw, w, h):
    px, py, pw, ph = phone_dims(w, h)
    draw_phone(draw, px, py, pw, min(ph, h-py+int(ph*0.05)))
    s = Image.new("RGBA", (pw, ph), (0,0,0,255))
    sd = ImageDraw.Draw(s)
    vgrad(sd, pw, ph, ["#0f0520","#0d1b3e","#162447","#1a2a5e"])

    # Lock screen style
    ctxt(sd, "9:41", int(ph*0.025), pw, F(FH, int(pw*0.18)))
    ctxt(sd, "Tuesday, March 3", int(ph*0.025)+int(pw*0.19), pw, F(FM, int(pw*0.04)), fill=(220,220,240))

    # Large widget
    wm = int(pw*0.05); wy = int(ph*0.14); ww = pw-2*wm; wh_ = int(ww*0.5)
    wid = Image.new("RGBA",(ww,wh_)); wd = ImageDraw.Draw(wid)
    vgrad(wd, ww, wh_, RAINBOW)
    for k in range(0, ww, 35):
        wd.line([(k,0),(k+wh_,wh_)], fill=(255,255,255,8), width=1)
    wm2 = Image.new("L",(ww,wh_),0)
    ImageDraw.Draw(wm2).rounded_rectangle([0,0,ww-1,wh_-1],radius=26,fill=255)
    # Widget content
    wd.text((24,18),"Proud Daily",font=F(FM,int(pw*0.028)),fill=(255,255,255,220))
    af = F(FR, int(pw*0.048))
    for i,line in enumerate(["You are enough","exactly as you are"]):
        wd.text((24,50+i*int(pw*0.06)),line,font=af,fill=(255,255,255))
    wd.text((24,wh_-36),"🔥 7 day streak",font=F(FM,int(pw*0.028)),fill=(255,255,255,200))
    s.paste(wid,(wm,wy),wm2)

    # Two medium widgets
    gap = int(pw*0.03); sw = (ww-gap)//2; sh = int(sw*0.95)
    sy_ = wy+wh_+int(pw*0.03)
    for i,(colors,title,body) in enumerate([
        (TRANS,"Coming Up","Be brave in\nyour truth today"),
        (BISEXUAL,"Today's Mood","😊 Grateful\n& Empowered")
    ]):
        sx = wm+i*(sw+gap)
        swid = Image.new("RGBA",(sw,sh)); swd = ImageDraw.Draw(swid)
        vgrad(swd, sw, sh, colors)
        for k in range(0,sw,30):
            swd.line([(k,0),(k+sh,sh)],fill=(255,255,255,8),width=1)
        sm = Image.new("L",(sw,sh),0)
        ImageDraw.Draw(sm).rounded_rectangle([0,0,sw-1,sh-1],radius=22,fill=255)
        swd.text((16,14),title,font=F(FM,int(pw*0.024)),fill=(255,255,255,200))
        for j,line in enumerate(body.split("\n")):
            swd.text((16,38+j*int(pw*0.042)),line,font=F(FR,int(pw*0.034)),fill=(255,255,255))
        s.paste(swid,(sx,sy_),sm)

    # Lock screen widget row (small)
    lwy = sy_ + sh + int(pw*0.04)
    lw_w = (ww - 2*gap) // 3; lw_h = int(lw_w * 0.9)
    for i,(colors,text) in enumerate([
        (OCEAN, "🧘 Mindful"),
        (SUNSET, "✨ 14 days"),
        (PASTEL, "💜 Self-Love")
    ]):
        lx = wm + i*(lw_w+gap)
        lwid = Image.new("RGBA",(lw_w,lw_h)); lwd = ImageDraw.Draw(lwid)
        vgrad(lwd, lw_w, lw_h, colors)
        lm = Image.new("L",(lw_w,lw_h),0)
        ImageDraw.Draw(lm).rounded_rectangle([0,0,lw_w-1,lw_h-1],radius=16,fill=255)
        lwd.text((10,lw_h//2-10),text,font=F(FR,int(pw*0.026)),fill=(255,255,255))
        s.paste(lwid,(lx,lwy),lm)

    visible_h = min(ph, h-py+int(h*0.02))
    vis = s.crop((0,0,pw,visible_h))
    img.paste(vis, (px, py), smask(pw, visible_h))

def c_journal(img, draw, w, h):
    px, py, pw, ph = phone_dims(w, h)
    draw_phone(draw, px, py, pw, min(ph, h-py+int(ph*0.05)))
    s = Image.new("RGBA", (pw, ph), (14,14,26,255))
    sd = ImageDraw.Draw(s)
    draw_status_bar(sd, pw)
    draw_tab_bar(sd, pw, ph, 3)
    draw_home_indicator(sd, pw, ph)
    tf = F(FB, int(pw*0.065))
    sd.text((int(pw*0.06), int(ph*0.055)), "Journal", font=tf, fill=(255,255,255))
    entries = [("Today","Feeling grateful for my community 💜","😊 Grateful",RAINBOW),
               ("Yesterday","Came out to a friend — it went great!","🥳 Proud",TRANS),
               ("Mar 1","Practiced self-love affirmations","😌 Calm",BISEXUAL),
               ("Feb 28","Reflected on my journey so far","🤔 Reflective",OCEAN),
               ("Feb 27","Finding strength in vulnerability","💪 Strong",LESBIAN)]
    m = int(pw*0.05); ey = int(ph*0.10); ch_ = int(ph*0.12); gap = int(pw*0.02)
    lf = F(FM, int(pw*0.028)); ef = F(FR, int(pw*0.032))
    for date,text,mood,colors in entries:
        card = Image.new("RGBA",(pw-2*m,ch_)); cd = ImageDraw.Draw(card)
        cd.rounded_rectangle([0,0,pw-2*m-1,ch_-1],radius=18,fill=(25,25,42))
        # Gradient accent bar
        acc = Image.new("RGBA",(5,ch_-24)); vgrad(ImageDraw.Draw(acc),5,ch_-24,colors)
        card.paste(acc,(14,12))
        cd.text((30,10),date,font=lf,fill=(140,140,170))
        cd.text((30,32),text,font=ef,fill=(235,235,255))
        cd.text((30,ch_-28),mood,font=lf,fill=(170,170,200))
        cm = Image.new("L",(pw-2*m,ch_),0)
        ImageDraw.Draw(cm).rounded_rectangle([0,0,pw-2*m-1,ch_-1],radius=18,fill=255)
        s.paste(card,(m,ey),cm); ey += ch_+gap
    visible_h = min(ph, h-py+int(h*0.02))
    vis = s.crop((0,0,pw,visible_h))
    img.paste(vis, (px, py), smask(pw, visible_h))

def c_streak(img, draw, w, h):
    px, py, pw, ph = phone_dims(w, h)
    draw_phone(draw, px, py, pw, min(ph, h-py+int(ph*0.05)))
    s = Image.new("RGBA", (pw, ph), (14,14,26,255))
    sd = ImageDraw.Draw(s)
    draw_status_bar(sd, pw)
    draw_tab_bar(sd, pw, ph, 2)
    draw_home_indicator(sd, pw, ph)
    tf = F(FB, int(pw*0.065))
    sd.text((int(pw*0.06), int(ph*0.055)), "Progress", font=tf, fill=(255,255,255))
    # Large streak display
    ctxt(sd, "🔥", int(ph*0.10), pw, F(FH, int(pw*0.10)))
    ctxt(sd, "14", int(ph*0.10)+int(pw*0.11), pw, F(FH, int(pw*0.14)))
    ctxt(sd, "Day Streak", int(ph*0.10)+int(pw*0.27), pw, F(FM, int(pw*0.038)), fill=(170,170,200))
    # Calendar
    m = int(pw*0.05); cy = int(ph*0.32)
    ctxt(sd, "March 2026", cy-int(pw*0.06), pw, F(FM, int(pw*0.035)))
    days = "SMTWTFS"
    cell = (pw-2*m)//7; lf = F(FM, int(pw*0.026))
    for i,d in enumerate(days):
        bb = sd.textbbox((0,0),d,font=lf)
        sd.text((m+i*cell+(cell-(bb[2]-bb[0]))//2, cy), d, font=lf, fill=(120,120,150))
    ry = cy+int(pw*0.05)
    for day in range(1,32):
        col = (day-1)%7; row = (day-1)//7
        cx_ = m+col*cell+cell//2; cy_ = ry+row*cell+cell//2
        r = cell//2-5
        if day <= 3:
            sd.ellipse([cx_-r,cy_-r,cx_+r,cy_+r], fill=hex_rgb(RAINBOW[day%len(RAINBOW)]))
        ds = str(day); bb = sd.textbbox((0,0),ds,font=lf)
        sd.text((cx_-(bb[2]-bb[0])//2, cy_-(bb[3]-bb[1])//2), ds, font=lf,
                fill=(255,255,255) if day<=3 else (70,70,100))
    # Stats
    sy_ = int(ph*0.70)
    stats_bg = Image.new("RGBA",(pw-2*m, int(pw*0.18)))
    sbd = ImageDraw.Draw(stats_bg)
    sbd.rounded_rectangle([0,0,pw-2*m-1,int(pw*0.18)-1],radius=18,fill=(25,25,42))
    sbm = Image.new("L",(pw-2*m,int(pw*0.18)),0)
    ImageDraw.Draw(sbm).rounded_rectangle([0,0,pw-2*m-1,int(pw*0.18)-1],radius=18,fill=255)
    s.paste(stats_bg,(m,sy_),sbm)
    stats = [("Total","89"),("Best Streak","21"),("Avg/Week","5.2")]
    sw = (pw-2*m)//3; bf_ = F(FB, int(pw*0.05))
    for i,(label,val) in enumerate(stats):
        sx = m+i*sw+sw//2
        bb = sd.textbbox((0,0),val,font=bf_)
        sd.text((sx-(bb[2]-bb[0])//2,sy_+int(pw*0.03)),val,font=bf_,fill=(255,255,255))
        bb2 = sd.textbbox((0,0),label,font=lf)
        sd.text((sx-(bb2[2]-bb2[0])//2,sy_+int(pw*0.09)),label,font=lf,fill=(130,130,165))
    visible_h = min(ph, h-py+int(h*0.02))
    vis = s.crop((0,0,pw,visible_h))
    img.paste(vis, (px, py), smask(pw, visible_h))

def c_sleep(img, draw, w, h):
    px, py, pw, ph = phone_dims(w, h)
    draw_phone(draw, px, py, pw, min(ph, h-py+int(ph*0.05)))
    s = Image.new("RGBA", (pw, ph), (6,6,16,255))
    sd = ImageDraw.Draw(s)
    # Stars
    random.seed(42)
    for _ in range(80):
        sx,sy_ = random.randint(0,pw), random.randint(0,ph)
        br = random.randint(40,160)
        sz = random.choice([1,1,1,2])
        sd.ellipse([sx-sz,sy_-sz,sx+sz,sy_+sz], fill=(br,br,min(br+50,255)))
    draw_status_bar(sd, pw)
    sd.text((int(pw*0.06), int(ph*0.055)), "Sleep Mode", font=F(FB, int(pw*0.06)), fill=(200,200,230))
    sd.text((int(pw*0.06), int(ph*0.055)+int(pw*0.07)), "Wind down with affirmations", font=F(FM, int(pw*0.03)), fill=(130,130,165))

    # Moon
    mcx, mcy = pw//2, int(ph*0.18)
    mr = int(pw*0.10)
    sd.ellipse([mcx-mr,mcy-mr,mcx+mr,mcy+mr], fill=(240,230,170))
    sd.ellipse([mcx-mr+int(mr*0.35),mcy-mr-int(mr*0.2),mcx+mr+int(mr*0.25),mcy+mr-int(mr*0.25)], fill=(6,6,16))
    # Glow
    for gr in range(3):
        glow_r = mr + 15 + gr*12
        sd.ellipse([mcx-glow_r,mcy-glow_r,mcx+glow_r,mcy+glow_r], outline=(240,230,170,15), width=2)

    # Affirmation
    af = F(FR, int(pw*0.05))
    for i, line in enumerate(["As I rest, I release", "what no longer serves me"]):
        bb = sd.textbbox((0,0),line,font=af)
        sd.text(((pw-(bb[2]-bb[0]))//2, int(ph*0.30)+i*int(pw*0.065)), line, font=af, fill=(200,200,230))

    # Sound wave
    wy = int(ph*0.46); wh_ = int(ph*0.06)
    bars = [0.3,0.5,0.8,0.6,0.9,0.7,0.4,0.6,0.8,0.5,0.3,0.7,0.9,0.6,0.4,0.5,0.7,0.3,0.6,0.8,0.5,0.7,0.4,0.6]
    bw = max(int(pw*0.012), 4)
    total_bw = len(bars)*bw + (len(bars)-1)*int(bw*0.8)
    bx = (pw-total_bw)//2
    for b in bars:
        bh = int(wh_*b)
        oc = hex_rgb(OCEAN[0]); tc = hex_rgb(OCEAN[2])
        t = b
        rc = int(oc[0]*(1-t)+tc[0]*t); gc = int(oc[1]*(1-t)+tc[1]*t); bc_ = int(oc[2]*(1-t)+tc[2]*t)
        sd.rounded_rectangle([bx, wy+wh_-bh, bx+bw, wy+wh_], radius=bw//2, fill=(rc,gc,bc_))
        bx += bw+int(bw*0.8)

    sf = F(FM, int(pw*0.032))
    ctxt(sd, "🌊 Ocean Waves", int(ph*0.54), pw, sf, fill=(140,140,175))

    # Timer pill
    tp = "🌙 Sleep timer: 30 min"
    tbb = sd.textbbox((0,0),tp,font=sf)
    tpw = tbb[2]-tbb[0]+30
    sd.rounded_rectangle([(pw-tpw)//2, int(ph*0.59), (pw+tpw)//2, int(ph*0.59)+36], radius=18, fill=(30,30,55))
    ctxt(sd, tp, int(ph*0.59)+6, pw, sf, fill=(160,160,195))

    # Playback controls
    cy_ = int(ph*0.67)
    controls = [("⏮",35), ("⏸",45), ("⏭",35)]
    cx_start = pw//2 - int(pw*0.18)
    gap_ = int(pw*0.18)
    for i,(icon,sz) in enumerate(controls):
        cx_ = cx_start + i*gap_
        r = sz
        sd.ellipse([cx_-r,cy_-r,cx_+r,cy_+r], fill=(35,35,55), outline=(60,60,85), width=2)
        cf = F(FM, int(pw*0.04) if i==1 else int(pw*0.032))
        bb = sd.textbbox((0,0),icon,font=cf)
        sd.text((cx_-(bb[2]-bb[0])//2, cy_-(bb[3]-bb[1])//2), icon, font=cf, fill=(200,200,230))

    # Volume slider
    vy = int(ph*0.75)
    sl_w = int(pw*0.6)
    sl_x = (pw-sl_w)//2
    sd.rounded_rectangle([sl_x, vy, sl_x+sl_w, vy+6], radius=3, fill=(40,40,60))
    filled = int(sl_w*0.65)
    sd.rounded_rectangle([sl_x, vy, sl_x+filled, vy+6], radius=3, fill=hex_rgb(OCEAN[0]))
    sd.ellipse([sl_x+filled-8, vy-5, sl_x+filled+8, vy+11], fill=(255,255,255))

    visible_h = min(ph, h-py+int(h*0.02))
    vis = s.crop((0,0,pw,visible_h))
    img.paste(vis, (px, py), smask(pw, visible_h))

# ━━━ Screenshot definitions ━━━
SCREENS = [
    (1, "01_daily_affirmation", "Daily affirmations made for you",  ["#120828","#1a0c3a","#0d1530"], c_home),
    (2, "02_hold_to_reveal",    "Hold to reveal your daily truth",  ["#0d1530","#151840","#0f1235"], c_hold),
    (3, "03_categories",        "9 LGBTQ+ affirmation categories",  ["#120828","#180a38","#0d1530"], c_cats),
    (4, "04_pride_themes",      "Express your pride, your way",     ["#180a38","#120828","#1a0c3a"], c_themes),
    (5, "05_widgets",           "Affirmations everywhere you look", ["#0d1530","#151840","#180a38"], c_widgets),
    (6, "06_journal",           "Track your journey",               ["#120828","#0d1530","#101535"], c_journal),
    (7, "07_streak",            "Build your streak",                ["#180a38","#120828","#0d1530"], c_streak),
    (8, "08_sleep_mode",        "Fall asleep affirmed",             ["#050510","#080818","#0a0a22"], c_sleep),
]

def make_screen(w, h, bg_colors, caption, screen_num, content_fn):
    img = Image.new("RGBA", (w, h), (0,0,0,255))
    d = ImageDraw.Draw(img)
    vgrad(d, w, h, bg_colors)
    cap_y = int(h * 0.04)
    fsize = int(w * 0.065)
    cap_font = F(FH, fsize)
    if screen_num == 1:
        rainbow_text(img, caption, cap_y, cap_font)
    else:
        d = ImageDraw.Draw(img)
        ctxt(d, caption, cap_y, w, cap_font)
    # Subtitle
    sub_y = cap_y + int(fsize * 1.3)
    subs = {
        1: "Start each day with pride & positivity",
        2: "A mindful moment, just for you",
        3: "Curated for the LGBTQ+ community",
        4: "10 pride flag themes to choose from",
        5: "Widgets for home screen & lock screen",
        6: "Reflect on your daily affirmation journey",
        7: "Stay consistent, stay proud",
        8: "Gentle affirmations for restful sleep",
    }
    d = ImageDraw.Draw(img)
    sub_font = F(FM, int(w * 0.035))
    ctxt(d, subs.get(screen_num, ""), sub_y, w, sub_font, fill=(220,220,240,200))
    content_fn(img, d, w, h)
    return img.convert("RGB")

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    total = 0
    for dev_name, (dw, dh) in DEVICES.items():
        dev_dir = os.path.join(OUTPUT_DIR, dev_name)
        os.makedirs(dev_dir, exist_ok=True)
        for num, name, caption, bg, fn in SCREENS:
            img = make_screen(dw, dh, bg, caption, num, fn)
            path = os.path.join(dev_dir, f"{name}.png")
            img.save(path, "PNG", optimize=True)
            total += 1
            print(f"  ✓ {dev_name}/{name}.png")
    print(f"\nGenerated {total} screenshots in {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
