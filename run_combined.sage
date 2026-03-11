"""
Complete standalone code for centralizer analysis
Copy and paste this entire file into SageMathCell to run
"""

from sage.all import *

# ============================================
# Lawrence-Krammer Matrix Generators
# ============================================

def LK_B3(q, t):
    """
    Return the Lawrence-Krammer representation matrices for B_3 (dimension 3)
    Using numerical/floating point matrices to avoid symbolic issues
    """
    # Convert to float to ensure numerical matrices
    q = float(q)
    t = float(t)
    
    sigma1 = matrix(RDF, [
        [-q**2 * t, 0, 0],
        [0, -q * t, 0],
        [0, 0, -t]
    ])
    
    # Avoid division by zero or symbolic expressions
    if q == 1:
        q = 1.000001  # Slight adjustment to avoid division by zero
    
    sigma2 = matrix(RDF, [
        [0, 0, -q * t * (1 - q**2) / (1 - q)],
        [0, -t, 0],
        [-(1 - q) / q, 0, -q**2 * t]
    ])
    
    return sigma1, sigma2

def random_braid(n, length, seed=None):
    """
    Generate a random braid word in B_n of given length
    """
    import random as pyrandom
    if seed is not None:
        pyrandom.seed(seed)
    
    word = []
    for _ in range(length):
        gen = pyrandom.randint(1, n-1)
        sign = 1 if pyrandom.random() < 0.5 else -1
        word.append(sign * gen)
    return word

def braid_word_to_matrix(word, generators):
    """
    Convert a braid word to a matrix product
    """
    nrows = generators[0].nrows()
    result = identity_matrix(RDF, nrows)
    
    for g in word:
        idx = abs(g) - 1
        if g > 0:
            result = result * generators[idx]
        else:
            # For inverse, we need to compute the matrix inverse
            result = result * generators[idx].inverse()
    return result

# ============================================
# Centralizer Analysis Functions
# ============================================

def centralizer_size(M, candidates):
    """
    Count how many candidate matrices commute with M
    Using numerical tolerance for floating point comparisons
    """
    count = 0
    for C in candidates:
        # Check if M*C ≈ C*M (within tolerance)
        diff = M * C - C * M
        if diff.norm() < 1e-10:
            count += 1
    return count

def enumerate_short_braids(n, max_length):
    """
    Enumerate all braid words up to given length
    """
    from itertools import product
    
    generators_forward = list(range(1, n))
    generators_backward = [-g for g in generators_forward]
    all_gens = generators_forward + generators_backward
    
    matrices = []
    
    # Get representation for B_3
    q, t = 2.0, 3.0
    gens = LK_B3(q, t)
    
    # Add identity matrix
    I = identity_matrix(RDF, gens[0].nrows())
    matrices.append(I)
    
    # Generate all words up to max_length
    for length in range(1, max_length+1):
        for word_tuple in product(all_gens, repeat=length):
            word = list(word_tuple)
            try:
                M = braid_word_to_matrix(word, gens)
                matrices.append(M)
            except Exception as e:
                # Skip if matrix not invertible or other error
                pass
    
    return matrices

# ============================================
# Main Analysis
# ============================================

print("="*60)
print("B₃ CENTRALIZER INTERSECTION ANALYSIS")
print("="*60)

n = 3
enumeration_length = 3  # Reduced to 3 for speed and reliability
num_samples = 10  # Reduced for testing

print(f"Braid group: B_{n}")
print(f"Enumerating all braids of length ≤ {enumeration_length}...")

# Get all short braids
short_braids = enumerate_short_braids(n, enumeration_length)
print(f"Found {len(short_braids)} matrices from short braids")
print()

# Test random braids
results = []
print("Testing random braids...")

for sample in range(num_samples):
    # Generate random braid
    word = random_braid(n, 10, seed=sample)
    q, t = 2.0, 3.0
    M = braid_word_to_matrix(word, LK_B3(q, t))
    
    # Compute centralizer intersection size
    size = centralizer_size(M, short_braids)
    results.append(size)
    
    print(f"Sample {sample+1:2d}: intersection size = {size}")

# Print summary
print("\n" + "="*60)
print("RESULTS SUMMARY")
print("="*60)
print(f"Mean: {sum(results)/len(results):.2f}")
print(f"Minimum: {min(results)}")
print(f"Maximum: {max(results)}")
print(f"All results: {results}")

# Statistics
unique_sizes = sorted(set(results))
print(f"\nUnique sizes observed: {unique_sizes}")
print(f"Percentage with size 1: {100 * results.count(1)/len(results):.1f}%")
