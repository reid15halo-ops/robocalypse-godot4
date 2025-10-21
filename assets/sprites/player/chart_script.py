import plotly.graph_objects as go
import numpy as np

# Create a 4-frame sprite sheet for a purple hacker character
# Each frame is 32x32 pixels, arranged horizontally
sprite_width = 32
sprite_height = 32
num_frames = 4

# Create pixel art data for each frame of the walking animation
frames = []

# Frame 1 - Standing position
frame1 = np.zeros((32, 32))
# Head (rows 8-15, cols 12-19)
frame1[8:16, 12:20] = 1
# Body (rows 16-24, cols 14-18)
frame1[16:25, 14:18] = 1
# Arms (rows 18-22)
frame1[18:23, 12:14] = 1  # Left arm
frame1[18:23, 18:20] = 1  # Right arm
# Legs (rows 24-30)
frame1[24:31, 14:16] = 1  # Left leg
frame1[24:31, 16:18] = 1  # Right leg

# Frame 2 - Left step
frame2 = np.zeros((32, 32))
frame2[8:16, 12:20] = 1  # Head
frame2[16:25, 14:18] = 1  # Body
frame2[18:23, 11:13] = 1  # Left arm forward
frame2[18:23, 19:21] = 1  # Right arm back
frame2[24:31, 13:15] = 1  # Left leg forward
frame2[24:31, 16:18] = 1  # Right leg

# Frame 3 - Center position
frame3 = np.zeros((32, 32))
frame3[8:16, 12:20] = 1  # Head
frame3[16:25, 14:18] = 1  # Body
frame3[18:23, 12:14] = 1  # Left arm
frame3[18:23, 18:20] = 1  # Right arm
frame3[24:31, 15:17] = 1  # Legs together

# Frame 4 - Right step
frame4 = np.zeros((32, 32))
frame4[8:16, 12:20] = 1  # Head
frame4[16:25, 14:18] = 1  # Body
frame4[18:23, 11:13] = 1  # Left arm back
frame4[18:23, 19:21] = 1  # Right arm forward
frame4[24:31, 14:16] = 1  # Left leg
frame4[24:31, 17:19] = 1  # Right leg forward

frames = [frame1, frame2, frame3, frame4]

# Create the full sprite sheet
sprite_sheet = np.zeros((32, 128))  # 32 height, 128 width (4 * 32)

for i, frame in enumerate(frames):
    start_col = i * 32
    end_col = (i + 1) * 32
    sprite_sheet[:, start_col:end_col] = frame

# Create the plot
fig = go.Figure()

# Add the sprite sheet as a heatmap with purple color
fig.add_trace(go.Heatmap(
    z=sprite_sheet,
    colorscale=[[0, 'rgba(255,255,255,0)'], [1, '#8A2BE2']],  # Transparent to purple
    showscale=False,
    hovertemplate='<extra></extra>',
    name=''
))

# Add subtle frame separators
for i in range(1, 4):
    fig.add_vline(x=i * 32 - 0.5, line=dict(color='lightgray', width=1, dash='dot'))

# Update layout for cleaner sprite sheet appearance
fig.update_layout(
    title=dict(
        text='Purple Hacker Walk Animation',
        font=dict(size=20, color='#8A2BE2'),
        x=0.5
    ),
    xaxis=dict(
        showgrid=False,
        zeroline=False,
        showticklabels=True,
        range=[-0.5, 127.5],
        tickmode='array',
        tickvals=[15.5, 47.5, 79.5, 111.5],
        ticktext=['Frame 1', 'Frame 2', 'Frame 3', 'Frame 4'],
        tickfont=dict(size=12)
    ),
    yaxis=dict(
        showgrid=False,
        zeroline=False,
        showticklabels=False,
        range=[-0.5, 31.5],
        scaleanchor='x',
        scaleratio=1
    ),
    plot_bgcolor='white',
    paper_bgcolor='white'
)

# Invert y-axis to match typical image coordinates
fig.update_yaxes(autorange='reversed')

# Remove axis titles for cleaner look
fig.update_xaxes(title_text='')
fig.update_yaxes(title_text='')

# Save the chart
fig.write_image('sprite_sheet.png')
fig.write_image('sprite_sheet.svg', format='svg')