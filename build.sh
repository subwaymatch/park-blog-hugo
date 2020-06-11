# Convert notebook files to HTML
jupyter nbconvert content/**/*.ipynb --to markdown

# Copy images for notebooks to static
cp -r content/notebooks/images/* static/images/

# Build hugo
hugo