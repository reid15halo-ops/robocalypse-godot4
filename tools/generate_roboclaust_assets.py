# Re-create all Roboclaust assets (static + animated) due to expired session.
# Outputs:
# - assets/sprites/ (PNGs)
# - assets/anim/ (animated sheets)
from PIL import Image, ImageDraw, ImageFont
import os, math, zipfile

# -------------------- Helpers --------------------
def img(size, color=(0,0,0,0)): return Image.new("RGBA", size, color)
def save(im, path): os.makedirs(os.path.dirname(path), exist_ok=True); im.save(path, "PNG"); return path
def add_noise(draw, w, h, color, density=0.05, seed=7):
    import random
    rnd = random.Random(seed)
    for _ in range(int(w*h*density)):
        x = rnd.randrange(0,w); y = rnd.randrange(0,h)
        draw.point((x,y), fill=color)

# Palette
BLACK=(0,0,0,255); WHITE=(255,255,255,255)
GRAY=(80,80,88,255); DARK_GRAY=(40,40,48,255)
CYAN=(0,220,220,255); NEON_BLUE=(0,170,255,255)
RED=(220,40,40,255); DARK_RED=(140,10,10,255)
BROWN=(120,70,50,255); ORANGE=(255,140,0,255)
YELLOW=(255,220,0,255); GREEN=(80,200,120,255)

# -------------------- Static Pack --------------------
base_dir = "assets/sprites"
os.makedirs(base_dir, exist_ok=True)

# Player 64x64
player = img((64,64))
d = ImageDraw.Draw(player)
d.rectangle((10,8,54,56), fill=DARK_GRAY, outline=BLACK)
d.ellipse((22,4,42,20), fill=BLACK, outline=(10,10,10,255))
d.rectangle((6,34,20,44), fill=(20,30,35,255), outline=BLACK)
d.rectangle((8,36,18,42), outline=CYAN)
d.rectangle((8,24,20,48), fill=GRAY, outline=BLACK)
d.rectangle((44,24,56,48), fill=GRAY, outline=BLACK)
d.rectangle((26,28,38,44), fill=(30,30,36,255), outline=(15,15,18,255))
for x in range(12,53,3): d.point((x,32), fill=CYAN)
for y in range(16,54,3): d.point((12,y), fill=CYAN); d.point((52,y), fill=CYAN)
d.rectangle((20,52,28,58), fill=BLACK)
d.rectangle((36,52,44,58), fill=BLACK)
save(player, f"{base_dir}/player_hacker_64.png")

# Enemies 40x40
def chassis_base(color, accent=None, size=(40,40), heavy=False, aero=False):
    im = img(size); d = ImageDraw.Draw(im); w,h=size
    d.rectangle((10,8,w-10,h-8), fill=color, outline=BLACK)
    d.ellipse((6,6,18,18), fill=color, outline=BLACK)
    d.ellipse((w-18,6,w-6,18), fill=color, outline=BLACK)
    d.ellipse((6,h-18,18,h-6), fill=color, outline=BLACK)
    d.ellipse((w-18,h-18,w-6,h-6), fill=color, outline=BLACK)
    d.ellipse((w//2-4,h//2-4,w//2+4,h//2+4), fill=BLACK, outline=WHITE)
    if accent:
        d.rectangle((w//2-8, 8, w//2+8, 10), fill=accent)
        for x in range(10,w-10,6): d.point((x,h-10), fill=accent)
    if aero:
        d.polygon([(4,h//2),(12,h//2-4),(12,h//2+4)], fill=BLACK)
        d.polygon([(w-4,h//2),(w-12,h//2-4),(w-12,h//2+4)], fill=BLACK)
    if heavy:
        d.rectangle((8,12,14,h-12), fill=BLACK)
        d.rectangle((w-14,12,w-8,h-12), fill=BLACK)
    return im

std = chassis_base(RED, accent=WHITE); save(std, f"{base_dir}/enemy_drone_standard_40.png")
fast = img((40,40)); fd = ImageDraw.Draw(fast)
fd.polygon([(20,6),(30,14),(20,22),(10,14)], fill=NEON_BLUE, outline=BLACK)
fd.polygon([(20,4),(32,14),(20,10)], fill=(0,120,150,255), outline=BLACK)
fd.ellipse((18,12,22,16), fill=BLACK, outline=WHITE); save(fast, f"{base_dir}/enemy_drone_fast_40.png")
heavy = chassis_base((100,40,30,255), accent=(200,120,80,255), heavy=True)
ImageDraw.Draw(heavy).point((16,14), fill=YELLOW); save(heavy, f"{base_dir}/enemy_drone_heavy_40.png")
kama = img((40,40)); kd=ImageDraw.Draw(kama)
kd.rectangle((10,10,30,30), fill=ORANGE, outline=BLACK)
kd.ellipse((16,16,24,24), fill=BLACK, outline=YELLOW); kd.line((24,16,28,10), fill=YELLOW, width=1)
save(kama, f"{base_dir}/enemy_drone_kamikaze_40.png")
snip = img((40,40)); sd=ImageDraw.Draw(snip)
sd.rectangle((8,8,32,32), fill=(40,120,60,255), outline=BLACK)
sd.rectangle((20,6,22,8), fill=BLACK); sd.rectangle((21,4,27,6), fill=BLACK)
sd.ellipse((14,14,26,26), fill=BLACK, outline=WHITE); save(snip, f"{base_dir}/enemy_drone_sniper_40.png")

# Boss 128x128
boss = img((128,128)); bd=ImageDraw.Draw(boss)
bd.rectangle((20,24,108,100), fill=(120,0,0,255), outline=BLACK)
bd.rectangle((48,8,80,28), fill=(60,0,0,255), outline=BLACK)
bd.rectangle((10,44,24,88), fill=(50,50,55,255), outline=BLACK)
bd.rectangle((104,44,118,88), fill=(50,50,55,255), outline=BLACK)
bd.rectangle((36,96,56,120), fill=BLACK, outline=BLACK)
bd.rectangle((72,96,92,120), fill=BLACK, outline=BLACK)
for x in range(24,104,4): bd.point((x,62), fill=RED)
bd.ellipse((58,56,70,68), fill=BLACK, outline=WHITE)
save(boss, f"{base_dir}/boss_mech_128.png")

# Tiles 64x64
def metal_tile(base=(70,70,78,255), rust=(140,60,30,255)):
    t = img((64,64), base); d=ImageDraw.Draw(t)
    d.line((0,32,64,32), fill=DARK_GRAY, width=1); d.line((32,0,32,64), fill=DARK_GRAY, width=1)
    add_noise(d,64,64,rust,density=0.02,seed=17); d.rectangle((6,50,16,60), fill=(110,50,25,255))
    return t
save(metal_tile(), f"{base_dir}/tile_scrapyard_64.png")
factory = img((64,64),(36,36,42,255)); df=ImageDraw.Draw(factory)
for x in range(0,64,8): df.line((x,0,x,64), fill=(20,20,24,255), width=1)
for y in range(0,64,8): df.line((0,y,64,y), fill=(24,24,28,255), width=1)
add_noise(df,64,64,(60,60,66,255),density=0.02,seed=3); save(factory, f"{base_dir}/tile_factory_64.png")
control = img((64,64),(20,24,30,255)); dc=ImageDraw.Draw(control)
for x in range(6,60,10): dc.line((x,6,x,58), fill=CYAN, width=1)
for y in range(10,60,10): dc.line((6,y,58,y), fill=CYAN, width=1)
for x in range(8,60,10):
    for y in range(8,60,10): dc.rectangle((x-1,y-1,x+1,y+1), fill=NEON_BLUE)
save(control, f"{base_dir}/tile_control_center_64.png")
server = img((64,64),(10,16,24,255)); ds=ImageDraw.Draw(server)
for x in range(0,64,16):
    ds.rectangle((x+2,6,x+14,58), fill=(14,22,34,255), outline=(6,10,16,255))
    for y in range(10,56,8): ds.line((x+4,y,x+12,y), fill=NEON_BLUE, width=1)
save(server, f"{base_dir}/tile_server_room_64.png")
def wall_tile(orientation="horizontal"):
    base = img((64,64),(50,8,8,255)); dw=ImageDraw.Draw(base); dw.rectangle((0,0,63,63), outline=BLACK)
    if orientation=="horizontal":
        for y in range(8,64,12): dw.rectangle((0,y,63,y+6), fill=(200,40,40,255)); dw.line((0,y+6,63,y+6), fill=BLACK)
    else:
        for x in range(8,64,12): dw.rectangle((x,0,x+6,63), fill=(200,40,40,255)); dw.line((x+6,0,x+6,63), fill=BLACK)
    return base
save(wall_tile("horizontal"), f"{base_dir}/tile_wall_warning_h_64.png")
save(wall_tile("vertical"), f"{base_dir}/tile_wall_warning_v_64.png")

# Items 32x32
health = img((32,32)); dh=ImageDraw.Draw(health)
dh.rectangle((4,4,28,28), fill=(10,30,10,255), outline=BLACK)
dh.rectangle((14,8,18,24), fill=WHITE); dh.rectangle((8,14,24,18), fill=WHITE)
save(health, f"{base_dir}/item_health_32.png")
scrap = img((32,32)); dscr=ImageDraw.Draw(scrap)
dscr.rectangle((4,6,28,26), fill=(180,150,40,255), outline=BLACK)
dscr.polygon([(6,24),(10,10),(16,12),(20,6),(26,14),(24,24)], fill=(230,200,80,255), outline=BLACK)
save(scrap, f"{base_dir}/item_scrap_32.png")
upgrade = img((32,32)); du=ImageDraw.Draw(upgrade)
du.rectangle((4,4,28,28), fill=(180,80,20,255), outline=BLACK)
du.polygon([(16,6),(22,16),(10,16)], fill=YELLOW, outline=BLACK)
du.rectangle((12,18,20,22), fill=BLACK); du.rectangle((18,16,24,18), fill=BLACK)
save(upgrade, f"{base_dir}/item_weapon_upgrade_32.png")

# Preview sheet
def pad(im, size_bg=(72,72)):
    bg = Image.new("RGBA", size_bg, (15,18,22,255))
    x=(size_bg[0]-im.width)//2; y=(size_bg[1]-im.height)//2; bg.alpha_composite(im,(x,y)); return bg
sections=[
    ("Player 64x64",[player]),
    ("Enemies 40x40",[std,fast,heavy,kama,snip]),
    ("Boss 128x128",[boss]),
    ("Tiles 64x64",[Image.open(f"{base_dir}/tile_scrapyard_64.png"),
                    Image.open(f"{base_dir}/tile_factory_64.png"),
                    Image.open(f"{base_dir}/tile_control_center_64.png"),
                    Image.open(f"{base_dir}/tile_server_room_64.png"),
                    Image.open(f"{base_dir}/tile_wall_warning_h_64.png"),
                    Image.open(f"{base_dir}/tile_wall_warning_v_64.png")]),
    ("Items 32x32",[health,scrap,upgrade]),
]
cols=8; thumbs=[]
for title, ims in sections:
    banner = Image.new("RGBA",(cols*72,16),(0,0,0,220))
    try:
        font = ImageFont.load_default(); ImageDraw.Draw(banner).text((4,2), title, fill=WHITE, font=font)
    except: pass
    thumbs.append(banner)
    row = Image.new("RGBA",(cols*72,72),(12,14,18,255)); x=0
    for im in ims:
        row.alpha_composite(pad(im)); x+=72
    thumbs.append(row)
H=sum(t.height for t in thumbs); atlas=Image.new("RGBA",(cols*72,H),(8,10,12,255)); y=0
for t in thumbs: atlas.alpha_composite(t,(0,y)); y+=t.height
save(atlas, f"{base_dir}/roboclaust_preview.png")

# -------------------- Animated Pack --------------------
anim_dir = "assets/anim"; os.makedirs(anim_dir, exist_ok=True)
def new_rgba(w,h,c=(0,0,0,0)): return Image.new("RGBA",(w,h),c)
def save_anim(im,name): p=f"{anim_dir}/{name}"; im.save(p,"PNG"); return p

# Player walk 8f
def draw_player_frame(phase):
    im = new_rgba(64,64); d=ImageDraw.Draw(im); bob=int(2*math.sin(phase*2*math.pi))
    d.rectangle((10,8+bob,54,56+bob), fill=DARK_GRAY, outline=BLACK)
    d.ellipse((22,4+bob,42,20+bob), fill=BLACK, outline=(10,10,10,255))
    d.rectangle((6,34+bob,20,44+bob), fill=(20,30,35,255), outline=BLACK)
    d.rectangle((8,36+bob,18,42+bob), outline=CYAN)
    d.rectangle((8,24+bob,20,48+bob), fill=GRAY, outline=BLACK)
    d.rectangle((44,24+bob,56,48+bob), fill=GRAY, outline=BLACK)
    d.rectangle((26,28+bob,38,44+bob), fill=(30,30,36,255), outline=(15,15,18,255))
    for x in range(12,53,3): d.point((x,32+bob), fill=CYAN)
    for y in range(16,54,3): d.point((12,y+bob), fill=CYAN); d.point((52,y+bob), fill=CYAN)
    swing=int(4*math.sin(phase*2*math.pi))
    d.rectangle((20+swing,52,28+swing,58), fill=BLACK)
    d.rectangle((36-swing,52,44-swing,58), fill=BLACK)
    return im
def make_sheet(draw_fn, frames, size):
    w,h=size; out=new_rgba(w*frames,h)
    for i in range(frames): out.alpha_composite(draw_fn(i/frames),(i*w,0))
    return out
player_sheet = make_sheet(draw_player_frame, 8, (64,64)); save_anim(player_sheet,"player_walk_64x64_8f.png")

# Drones 6f rotor
def draw_drone_body(kind):
    im=new_rgba(40,40); d=ImageDraw.Draw(im)
    if kind=="standard":
        d.rectangle((10,8,30,32), fill=RED, outline=BLACK)
        d.ellipse((6,6,18,18), fill=RED, outline=BLACK); d.ellipse((22,6,34,18), fill=RED, outline=BLACK)
        d.ellipse((6,22,18,34), fill=RED, outline=BLACK); d.ellipse((22,22,34,34), fill=RED, outline=BLACK)
        d.ellipse((18,18,22,22), fill=BLACK, outline=WHITE)
    if kind=="fast":
        d.polygon([(20,6),(30,14),(20,22),(10,14)], fill=NEON_BLUE, outline=BLACK)
        d.polygon([(20,4),(32,14),(20,10)], fill=(0,120,150,255), outline=BLACK)
        d.ellipse((18,12,22,16), fill=BLACK, outline=WHITE)
    if kind=="heavy":
        d.rectangle((10,8,30,32), fill=(100,40,30,255), outline=BLACK)
        d.rectangle((8,12,14,28), fill=BLACK); d.rectangle((26,12,32,28), fill=BLACK)
        d.ellipse((18,18,22,22), fill=BLACK, outline=YELLOW)
    if kind=="kamikaze":
        d.rectangle((10,10,30,30), fill=ORANGE, outline=BLACK)
        d.ellipse((16,16,24,24), fill=BLACK, outline=YELLOW); d.line((24,16,28,10), fill=YELLOW, width=1)
    if kind=="sniper":
        d.rectangle((8,8,32,32), fill=(40,120,60,255), outline=BLACK)
        d.rectangle((20,6,22,8), fill=BLACK); d.rectangle((21,4,27,6), fill=BLACK)
        d.ellipse((14,14,26,26), fill=BLACK, outline=WHITE)
    return im
def draw_rotor(im, angle_deg, radius=12, color=(0,0,0,200)):
    d=ImageDraw.Draw(im); cx,cy=im.width//2, im.height//2
    for mul in (0,90):
        a=math.radians(angle_deg+mul); x=cx+int(math.cos(a)*radius); y=cy+int(math.sin(a)*radius)
        d.line((cx,cy,x,y), fill=color, width=2)
    d.ellipse((cx-3,cy-3,cx+3,cy+3), fill=(30,30,30,220))
def drone_sheet(kind, frames=6):
    w=h=40; sheet=new_rgba(w*frames,h)
    for i in range(frames):
        base=draw_drone_body(kind); bob=int(1*math.sin(i/frames*2*math.pi))
        fr=new_rgba(w,h); fr.alpha_composite(base,(0,bob))
        angle=(i*(360/frames))%360; draw_rotor(fr, angle, radius=14 if kind!="fast" else 10)
        sheet.alpha_composite(fr,(i*w,0))
    return sheet
for kind in ["standard","fast","heavy","kamikaze","sniper"]:
    save_anim(drone_sheet(kind), f"drone_{kind}_40x40_6f.png")

# Explosions 12f 64x64
def explosion_sheet(inner, outer, frames=12, size=64):
    w=h=size; sheet=new_rgba(w*frames,h); cx=cy=size//2
    for i in range(frames):
        t=i/(frames-1); fr=new_rgba(w,h); d=ImageDraw.Draw(fr)
        r=int(4 + t*26); d.ellipse((cx-r,cy-r,cx+r,cy+r), outline=outer, width=2)
        r2=int(max(0,10 - t*10));
        if r2>0: d.ellipse((cx-r2,cy-r2,cx+r2,cy+r2), fill=inner, outline=(0,0,0,120))
        n=10
        for k in range(n):
            ang = 2*math.pi*(k/n) + t*3; dist=int(8 + t*24 + (k%3))
            x = cx + int(math.cos(ang)*dist); y = cy + int(math.sin(ang)*dist)
            d.rectangle((x-1,y-1,x+1,y+1), fill=outer)
        sheet.alpha_composite(fr,(i*w,0))
    return sheet
save_anim(explosion_sheet((255,180,40,255),(255,240,120,255)), "explosion_generic_64x64_12f.png")
save_anim(explosion_sheet((255,170,0,255),(255,220,0,255)), "explosion_kamikaze_64x64_12f.png")

# Boss core pulse 8f 128x128
def boss_core_pulse(frames=8):
    w=h=128; sheet=new_rgba(w*frames,h)
    for i in range(frames):
        phase=i/frames; base=new_rgba(128,128); bd=ImageDraw.Draw(base)
        bd.rectangle((20,24,108,100), fill=(120,0,0,255), outline=BLACK)
        bd.rectangle((48,8,80,28), fill=(60,0,0,255), outline=BLACK)
        bd.rectangle((10,44,24,88), fill=(50,50,55,255), outline=BLACK)
        bd.rectangle((104,44,118,88), fill=(50,50,55,255), outline=BLACK)
        bd.rectangle((36,96,56,120), fill=BLACK, outline=BLACK); bd.rectangle((72,96,92,120), fill=BLACK, outline=BLACK)
        for x in range(24,104,4): bd.point((x,62), fill=RED)
        r = 6 + int(3*math.sin(phase*2*math.pi))
        bd.ellipse((64-r,62-r,64+r,62+r), fill=(0,0,0,255), outline=WHITE)
        glow=new_rgba(128,128); g=ImageDraw.Draw(glow); rg=12 + int(6*math.sin(phase*2*math.pi))
        g.ellipse((64-rg,62-rg,64+rg,62+rg), fill=(255,40,40,80)); base.alpha_composite(glow,(0,0))
        sheet.alpha_composite(base,(i*w,0))
    return sheet
save_anim(boss_core_pulse(), "boss_core_pulse_128x128_8f.png")

# Boss muzzle flash overlay 6f 64x64
def boss_muzzle_flash(frames=6):
    w=h=64; sheet=new_rgba(w*frames,h)
    for i in range(frames):
        t=i/(frames-1); fr=new_rgba(w,h); d=ImageDraw.Draw(fr)
        length=int(8 + t*40); width=int(4 + t*10)
        d.polygon([(6,32-width),(6,32+width),(6+length,32)], fill=(255,230,160,220))
        d.polygon([(6,32-(width//2)), (6,32+(width//2)), (6+length//2,32)], fill=(255,200,60,240))
        sheet.alpha_composite(fr,(i*w,0))
    return sheet
save_anim(boss_muzzle_flash(), "boss_muzzle_flash_overlay_64x64_6f.png")

print("Asset generation complete!")
print(f"Static assets: {base_dir}")
print(f"Animated assets: {anim_dir}")
