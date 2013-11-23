/*
 * Meteor adaptation of Secure Remote Password 6a implementation by Tom Cocagne.
 *
 * Copyright (c) 2013 Jesse Bounds. All rights reserved.
 *
 * Copyright (c) 2010 Tom Cocagne. All rights reserved.
 * http://csrp.googlecode.com/p/csrp/
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *   * Neither the name of the Google Code nor the
 *     names of its contributors may be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL TOM COCAGNE BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF 
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */

#ifdef WIN32
    #include <Wincrypt.h>
#else
    #include <sys/time.h>
#endif

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include <bn.h>
#include <sha.h>
#include <crypto.h>
#include <rand.h>
#import <ctype.h>
//#import <c++/4.2.1/ext/functional>


#include "srp.h"

static int g_initialized = 0;



struct NGHex 
{
    const char * n_hex;
    const char * g_hex;
};

/* All constants here were pulled from Appendix A of RFC 5054 */
static struct NGHex global_Ng_constants[] = {
 { /* 1024 */
   "EEAF0AB9ADB38DD69C33F80AFA8FC5E86072618775FF3C0B9EA2314C9C256576D674DF7496"
   "EA81D3383B4813D692C6E0E0D5D8E250B98BE48E495C1D6089DAD15DC7D7B46154D6B6CE8E"
   "F4AD69B15D4982559B297BCF1885C529F566660E57EC68EDBC3C05726CC02FD4CBF4976EAA"
   "9AFD5138FE8376435B9FC61D2FC0EB06E3",
   "2"
 },
 { /* 2048 */
   "AC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050A37329CBB4"
   "A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50E8083969EDB767B0CF60"
   "95179A163AB3661A05FBD5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF"
   "747359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A436C6481F1D2B907"
   "8717461A5B9D32E688F87748544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB37861"
   "60279004E57AE6AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DB"
   "FBB694B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF73",
   "2"
 },
 { /* 4096 */
   "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E08"
   "8A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B"
   "302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9"
   "A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE6"
   "49286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8"
   "FD24CF5F83655D23DCA3AD961C62F356208552BB9ED529077096966D"
   "670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C"
   "180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF695581718"
   "3995497CEA956AE515D2261898FA051015728E5A8AAAC42DAD33170D"
   "04507A33A85521ABDF1CBA64ECFB850458DBEF0A8AEA71575D060C7D"
   "B3970F85A6E1E4C7ABF5AE8CDB0933D71E8C94E04A25619DCEE3D226"
   "1AD2EE6BF12FFA06D98A0864D87602733EC86A64521F2B18177B200C"
   "BBE117577A615D6C770988C0BAD946E208E24FA074E5AB3143DB5BFC"
   "E0FD108E4B82D120A92108011A723C12A787E6D788719A10BDBA5B26"
   "99C327186AF4E23C1A946834B6150BDA2583E9CA2AD44CE8DBBBC2DB"
   "04DE8EF92E8EFC141FBECAA6287C59474E6BC05D99B2964FA090C3A2"
   "233BA186515BE7ED1F612970CEE2D7AFB81BDD762170481CD0069127"
   "D5B05AA993B4EA988D8FDDC186FFB7DC90A6C08F4DF435C934063199"
   "FFFFFFFFFFFFFFFF",
   "5"
 },
 { /* 8192 */
   "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E08"
   "8A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B"
   "302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9"
   "A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE6"
   "49286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8"
   "FD24CF5F83655D23DCA3AD961C62F356208552BB9ED529077096966D"
   "670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C"
   "180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF695581718"
   "3995497CEA956AE515D2261898FA051015728E5A8AAAC42DAD33170D"
   "04507A33A85521ABDF1CBA64ECFB850458DBEF0A8AEA71575D060C7D"
   "B3970F85A6E1E4C7ABF5AE8CDB0933D71E8C94E04A25619DCEE3D226"
   "1AD2EE6BF12FFA06D98A0864D87602733EC86A64521F2B18177B200C"
   "BBE117577A615D6C770988C0BAD946E208E24FA074E5AB3143DB5BFC"
   "E0FD108E4B82D120A92108011A723C12A787E6D788719A10BDBA5B26"
   "99C327186AF4E23C1A946834B6150BDA2583E9CA2AD44CE8DBBBC2DB"
   "04DE8EF92E8EFC141FBECAA6287C59474E6BC05D99B2964FA090C3A2"
   "233BA186515BE7ED1F612970CEE2D7AFB81BDD762170481CD0069127"
   "D5B05AA993B4EA988D8FDDC186FFB7DC90A6C08F4DF435C934028492"
   "36C3FAB4D27C7026C1D4DCB2602646DEC9751E763DBA37BDF8FF9406"
   "AD9E530EE5DB382F413001AEB06A53ED9027D831179727B0865A8918"
   "DA3EDBEBCF9B14ED44CE6CBACED4BB1BDB7F1447E6CC254B33205151"
   "2BD7AF426FB8F401378CD2BF5983CA01C64B92ECF032EA15D1721D03"
   "F482D7CE6E74FEF6D55E702F46980C82B5A84031900B1C9E59E7C97F"
   "BEC7E8F323A97A7E36CC88BE0F1D45B7FF585AC54BD407B22B4154AA"
   "CC8F6D7EBF48E1D814CC5ED20F8037E0A79715EEF29BE32806A1D58B"
   "B7C5DA76F550AA3D8A1FBFF0EB19CCB1A313D55CDA56C9EC2EF29632"
   "387FE8D76E3C0468043E8F663F4860EE12BF2D5B0B7474D6E694F91E"
   "6DBE115974A3926F12FEE5E438777CB6A932DF8CD8BEC4D073B931BA"
   "3BC832B68D9DD300741FA7BF8AFC47ED2576F6936BA424663AAB639C"
   "5AE4F5683423B4742BF1C978238F16CBE39D652DE3FDB8BEFC848AD9"
   "22222E04A4037C0713EB57A81A23F0C73473FC646CEA306B4BCBC886"
   "2F8385DDFA9D4B7FA2C087E879683303ED5BDD3A062B3CF5B3A278A6"
   "6D2A13F83F44F82DDF310EE074AB6A364597E899A0255DC164F31CC5"
   "0846851DF9AB48195DED7EA1B1D510BD7EE74D73FAF36BC31ECFA268"
   "359046F4EB879F924009438B481C6CD7889A002ED5EE382BC9190DA6"
   "FC026E479558E4475677E9AA9E3050E2765694DFC81F56E880B96E71"
   "60C980DD98EDD3DFFFFFFFFFFFFFFFFF",
   "13"
 },
 {0,0} /* null sentinel */
};

static NGConstant * new_ng( SRP_NGType ng_type, const char * n_hex, const char * g_hex )
{
    NGConstant * ng   = (NGConstant *) malloc( sizeof(NGConstant) );
    ng->N             = BN_new();
    ng->g             = BN_new();

    if( !ng || !ng->N || !ng->g )
       return 0;

    if ( ng_type != SRP_NG_CUSTOM )
    {
        n_hex = global_Ng_constants[ ng_type ].n_hex;
        g_hex = global_Ng_constants[ ng_type ].g_hex;
    }
        
    BN_hex2bn( &ng->N, n_hex );
    BN_hex2bn( &ng->g, g_hex );
    
    return ng;
}

static void delete_ng( NGConstant * ng )
{
   if (ng)
   {
      BN_free( ng->N );
      BN_free( ng->g );
      ng->N = 0;
      ng->g = 0;
      free(ng);
   }
}

typedef union 
{
    SHA_CTX    sha;
    SHA256_CTX sha256;
    SHA512_CTX sha512;
} HashCTX;

struct SRPVerifier
{
    SRP_HashAlgorithm  hash_alg;
    NGConstant        *ng;
    
    const char          * username;
    const unsigned char * bytes_B;
    int                   authenticated;

    unsigned char M           [SHA512_DIGEST_LENGTH];
    unsigned char H_AMK       [SHA512_DIGEST_LENGTH];
    unsigned char session_key [SHA512_DIGEST_LENGTH];
};

static int hash_init( SRP_HashAlgorithm alg, HashCTX *c )
{
    switch (alg)
    {
      case SRP_SHA1  : return SHA1_Init( &c->sha );
      case SRP_SHA224: return SHA224_Init( &c->sha256 );
      case SRP_SHA256: return SHA256_Init( &c->sha256 );
      case SRP_SHA384: return SHA384_Init( &c->sha512 );
      case SRP_SHA512: return SHA512_Init( &c->sha512 );
      default:
        return -1;
    }
}

static int hash_update( SRP_HashAlgorithm alg, HashCTX *c, const void *data, size_t len )
{
    switch (alg)
    {
      case SRP_SHA1  : return SHA1_Update( &c->sha, data, len );
      case SRP_SHA224: return SHA224_Update( &c->sha256, data, len );
      case SRP_SHA256: return SHA256_Update( &c->sha256, data, len );
      case SRP_SHA384: return SHA384_Update( &c->sha512, data, len );
      case SRP_SHA512: return SHA512_Update( &c->sha512, data, len );
      default:
        return -1;
    }
}

static int hash_final( SRP_HashAlgorithm alg, HashCTX *c, unsigned char *md )
{
    switch (alg)
    {
      case SRP_SHA1  : return SHA1_Final( md, &c->sha );
      case SRP_SHA224: return SHA224_Final( md, &c->sha256 );
      case SRP_SHA256: return SHA256_Final( md, &c->sha256 );
      case SRP_SHA384: return SHA384_Final( md, &c->sha512 );
      case SRP_SHA512: return SHA512_Final( md, &c->sha512 );
      default:
        return -1;
    }
}

static unsigned char * hash( SRP_HashAlgorithm alg, const unsigned char *d, size_t n, unsigned char *md )
{
    switch (alg)
    {
      case SRP_SHA1  : return SHA1( d, n, md );
      case SRP_SHA224: return SHA224( d, n, md );
      case SRP_SHA256: return SHA256( d, n, md );
      case SRP_SHA384: return SHA384( d, n, md );
      case SRP_SHA512: return SHA512( d, n, md );
      default:
        return 0;
    }
}

static int hash_length( SRP_HashAlgorithm alg )
{
    switch (alg)
    {
      case SRP_SHA1  : return SHA_DIGEST_LENGTH;
      case SRP_SHA224: return SHA224_DIGEST_LENGTH;
      case SRP_SHA256: return SHA256_DIGEST_LENGTH;
      case SRP_SHA384: return SHA384_DIGEST_LENGTH;
      case SRP_SHA512: return SHA512_DIGEST_LENGTH;
      default:
        return -1;
    }
}

static BIGNUM * H_nn( SRP_HashAlgorithm alg, const BIGNUM * n1, const BIGNUM * n2 )
{
    unsigned char   buff[ SHA256_DIGEST_LENGTH ];
    int             len_n1 = BN_num_bytes(n1);
    int             len_n2 = BN_num_bytes(n2);
    int             nbytes = len_n1 + len_n2;
    unsigned char * bin    = (unsigned char *) malloc( nbytes );
    if (!bin)
       return 0;
    BN_bn2bin(n1, bin);
    BN_bn2bin(n2, bin + len_n1);
    hash( alg, bin, nbytes, buff );
    free(bin);
    return BN_bin2bn(buff, hash_length(alg), NULL);
}

static void update_hash_n( SRP_HashAlgorithm alg, HashCTX *ctx, const BIGNUM * n )
{
    unsigned long len = BN_num_bytes(n);
    unsigned char * n_bytes = (unsigned char *) malloc( len );
    if (!n_bytes)
       return;
    BN_bn2bin(n, n_bytes);
    hash_update(alg, ctx, n_bytes, len);
    free(n_bytes);
}

static void hash_num( SRP_HashAlgorithm alg, const BIGNUM * n, unsigned char * dest )
{
    int             nbytes = BN_num_bytes(n);
    unsigned char * bin    = (unsigned char *) malloc( nbytes );
    if(!bin)
       return;
    BN_bn2bin(n, bin);
    hash( alg, bin, nbytes, dest );
    free(bin);
}

static void calculate_M( SRP_HashAlgorithm alg, NGConstant *ng, unsigned char * dest, const char * I, const BIGNUM * s,
                         const BIGNUM * A, const BIGNUM * B, const unsigned char * K )
{
    unsigned char H_N[ SHA256_DIGEST_LENGTH ];
    unsigned char H_g[ SHA256_DIGEST_LENGTH ];
    unsigned char H_I[ SHA256_DIGEST_LENGTH ];
    unsigned char H_xor[ SHA256_DIGEST_LENGTH ];
    HashCTX       ctx;
    int           i = 0;
    int           hash_len = hash_length(alg);
        
    hash_num( alg, ng->N, H_N );
    hash_num( alg, ng->g, H_g );
    
    hash(alg, (const unsigned char *)I, strlen(I), H_I);
    
    
    for (i=0; i < hash_len; i++ )
        H_xor[i] = H_N[i] ^ H_g[i];
    
    hash_init( alg, &ctx );
    
    hash_update( alg, &ctx, H_xor, hash_len );
    hash_update( alg, &ctx, H_I,   hash_len );
    update_hash_n( alg, &ctx, s );
    update_hash_n( alg, &ctx, A );
    update_hash_n( alg, &ctx, B );
    hash_update( alg, &ctx, K, hash_len );
    
    hash_final( alg, &ctx, dest );
}

static void calculate_H_AMK( SRP_HashAlgorithm alg, unsigned char *dest, const BIGNUM * A, const unsigned char * M, const unsigned char * K )
{
    HashCTX ctx;
    
    hash_init( alg, &ctx );
    
    update_hash_n( alg, &ctx, A );
    hash_update( alg, &ctx, M, hash_length(alg) );
    hash_update( alg, &ctx, K, hash_length(alg) );
    
    hash_final( alg, &ctx, dest );
}

static void init_random()
{    
    if (g_initialized)
        return;
    
#ifdef WIN32
    HCRYPTPROV wctx;
#else
    FILE   *fp   = 0;
#endif
    
    unsigned char buff[64];

#ifdef WIN32
        CryptAcquireContext(&wctx, NULL, NULL, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT);
        CryptGenRandom(wctx, sizeof(buff), (BYTE*) buff);
        CryptReleaseContext(wctx, 0);
        g_initialized = 1;
#else
        fp = fopen("/dev/urandom", "r");
        
        if (fp)
        {
            fread(buff, sizeof(buff), 1, fp);
            fclose(fp);
            g_initialized = 1;
        }
#endif

    if (g_initialized)
       RAND_seed( buff, sizeof(buff) );
}

char * convert_to_lower(char *input)
{
	char *ptr = input;
	while (*ptr) {
		if (*ptr >= 'A' && *ptr <= 'F')
			*ptr -= 'A' - 'a';
		(void)*ptr++;
	}
    
	return input;
}

///
// External API functions
///

void srp_random_seed( const unsigned char * random_data, int data_length )
{
    g_initialized = 1;

    if (random_data)
        RAND_seed( random_data, data_length );
}

/* Out: bytes_B, len_B.
 * 
 * On failure, bytes_B will be set to NULL and len_B will be set to 0
 */
struct SRPVerifier *  srp_verifier_new( SRP_HashAlgorithm alg, SRP_NGType ng_type, const char * username,
                                        const unsigned char * bytes_s, int len_s, 
                                        const unsigned char * bytes_v, int len_v,
                                        const unsigned char * bytes_A, int len_A,
                                        const unsigned char ** bytes_B, int * len_B,
                                        const char * n_hex, const char * g_hex )
{
    BIGNUM             *s    = BN_bin2bn(bytes_s, len_s, NULL);
    BIGNUM             *v    = BN_bin2bn(bytes_v, len_v, NULL);
    BIGNUM             *A    = BN_bin2bn(bytes_A, len_A, NULL);
    BIGNUM             *u    = 0;
    BIGNUM             *B    = BN_new();
    BIGNUM             *S    = BN_new();
    BIGNUM             *b    = BN_new();
    BIGNUM             *k    = 0;
    BIGNUM             *tmp1 = BN_new();
    BIGNUM             *tmp2 = BN_new();
    BN_CTX             *ctx  = BN_CTX_new();
    int                 ulen = strlen(username) + 1;
    NGConstant         *ng   = new_ng( ng_type, n_hex, g_hex );
    struct SRPVerifier *ver  = 0;

    *len_B   = 0;
    *bytes_B = 0;
    
    if( !s || !v || !A || !B || !S || !b || !tmp1 || !tmp2 || !ctx || !ng )
       goto cleanup_and_exit;
    
    ver = (struct SRPVerifier *) malloc( sizeof(struct SRPVerifier) );

    if (!ver)
       goto cleanup_and_exit;

    init_random(); /* Only happens once */
    
    ver->username = (char *) malloc( ulen );
    ver->hash_alg = alg;
    ver->ng       = ng;

    if (!ver->username)
    {
       free(ver);
       ver = 0;
       goto cleanup_and_exit;
    }
    
    memcpy( (char*)ver->username, username, ulen );
    
    ver->authenticated = 0;
        
    /* SRP-6a safety check */
    BN_mod(tmp1, A, ng->N, ctx);
    if ( !BN_is_zero(tmp1) )
    {
       BN_rand(b, 256, -1, 0);
       
       k = H_nn(alg, ng->N, ng->g);
       
       /* B = kv + g^b */
       BN_mul(tmp1, k, v, ctx);
       BN_mod_exp(tmp2, ng->g, b, ng->N, ctx);
       BN_add(B, tmp1, tmp2);
       
       u = H_nn(alg, A, B);
       
       /* S = (A *(v^u)) ^ b */
       BN_mod_exp(tmp1, v, u, ng->N, ctx);
       BN_mul(tmp2, A, tmp1, ctx);
       BN_mod_exp(S, tmp2, b, ng->N, ctx);
       
       hash_num(alg, S, ver->session_key);
       
       calculate_M( alg, ng, ver->M, username, s, A, B, ver->session_key );
       calculate_H_AMK( alg, ver->H_AMK, A, ver->M, ver->session_key );
       
       *len_B   = BN_num_bytes(B);
       *bytes_B = malloc( *len_B );
       
       if( !*bytes_B )
       {
          free( (void*) ver->username );
          free( ver );
          ver = 0;
          *len_B = 0;
          goto cleanup_and_exit;
       }
       
       BN_bn2bin( B, (unsigned char *) *bytes_B );
          
       ver->bytes_B = *bytes_B;
    }
    
 cleanup_and_exit:
    BN_free(s);
    BN_free(v);
    BN_free(A);
    if (u) BN_free(u);
    if (k) BN_free(k);
    BN_free(B);
    BN_free(S);
    BN_free(b);
    BN_free(tmp1);
    BN_free(tmp2);
    BN_CTX_free(ctx);
    
    return ver;
}

void srp_verifier_delete( struct SRPVerifier * ver )
{
   if (ver)
   {
      delete_ng( ver->ng );
      free( (char *) ver->username );
      free( (unsigned char *) ver->bytes_B );
      memset(ver, 0, sizeof(*ver));
      free( ver );
   }
}

int srp_verifier_is_authenticated( struct SRPVerifier * ver )
{
    return ver->authenticated;
}

const char * srp_verifier_get_username( struct SRPVerifier * ver )
{
    return ver->username;
}

const unsigned char * srp_verifier_get_session_key( struct SRPVerifier * ver, int * key_length )
{
    if (key_length)
        *key_length = hash_length( ver->hash_alg );
    return ver->session_key;
}

int srp_verifier_get_session_key_length( struct SRPVerifier * ver )
{
    return hash_length( ver->hash_alg );
}

/* user_M must be exactly SHA512_DIGEST_LENGTH bytes in size */
void srp_verifier_verify_session( struct SRPVerifier * ver, const unsigned char * user_M, const unsigned char ** bytes_HAMK )
{
    if ( memcmp( ver->M, user_M, hash_length(ver->hash_alg) ) == 0 )
    {
        ver->authenticated = 1;
        *bytes_HAMK = ver->H_AMK;
    }
    else
        *bytes_HAMK = NULL;
}

SRPUser * srp_user_new_with_a(SRP_HashAlgorithm alg,
                              SRP_NGType ng_type,
                              const char *username,
                              const char *password,
                              const char *n_hex,
                              const char *g_hex,
                              BIGNUM *a) {
    SRPUser *usr = (SRPUser *)malloc(sizeof(SRPUser));
    int username_length = strlen(username) + 1;
    int password_length = strlen(password) + 1;
    
    if (!usr) goto err_exit;

    init_random();
    
    usr->hash_alg = alg;
    usr->ng = new_ng(ng_type, n_hex, g_hex);
    usr->a = a;
    usr->A = BN_new();
    usr->S = BN_new();
    
    if (!usr->ng || !usr->a || !usr->A || !usr->S) goto err_exit;
    
    usr->username = (const char *) malloc(username_length);
    usr->password = (const char *) malloc(password_length);
    usr->password_len = password_length;
    
    if (!usr->username || !usr->password) goto err_exit;
    
    memcpy((char *)usr->username, username, username_length);
    memcpy((char *)usr->password, password, password_length);
    
    usr->authenticated = 0;
    usr->bytes_A = 0;
    
    return usr;
    
err_exit:
    if (usr) {
        BN_free(usr->a);
        BN_free(usr->A);
        BN_free(usr->S);
        if (usr->username) free((void*)usr->username);
        if (usr->password) {
            memset((void*)usr->password, 0, usr->password_len);
            free((void*)usr->password);
        }
        free(usr);
    }
    return 0;
}

SRPUser * srp_user_new(SRP_HashAlgorithm alg,
                       SRP_NGType ng_type,
                       const char *username,
                       const char *password,
                       const char *n_hex,
                       const char *g_hex) {
    BIGNUM *a = BN_new();
    BN_rand(a, 256, -1, 0);
    return srp_user_new_with_a(alg, ng_type, username, password, n_hex, g_hex, a);
}

void srp_user_delete( SRPUser * usr ) {
    if(usr) {
        delete_ng(usr->ng);
        BN_free(usr->a);
        BN_free(usr->A);
        BN_free(usr->S);
        memset((void*)usr->password, 0, usr->password_len);
        free((char *)usr->password);
        usr->password = NULL;
        free((char *)usr->username);
        usr->username = NULL;
        free(usr);
        usr = NULL;
    }
}

int srp_user_is_authenticated( SRPUser * usr)
{
    return usr->authenticated;
}

/* Output: username, bytes_A, len_A, Astr */
const char * srp_user_start_authentication(SRPUser *usr) {
    BN_CTX *ctx = BN_CTX_new();
    BN_mod_exp(usr->A, usr->ng->g, usr->a, usr->ng->N, ctx);
    BIGNUM *modCheck = BN_new();
    BN_mod(modCheck, usr->A, usr->ng->N, ctx);
    BN_free(modCheck);
    BN_CTX_free(ctx);
    
    int len_A = BN_num_bytes(usr->A);
    unsigned char *bytes_A = malloc(len_A);
    
    BN_bn2bin(usr->A, bytes_A);
    usr->bytes_A = bytes_A;
    usr->Astr = convert_to_lower(BN_bn2hex(usr->A));
    
    free(bytes_A);
    
    return usr->Astr;
}

void meteor_user_generate_u(SRPUser *usr,
                            char const *Bstr,
                            unsigned char *buff,
                            BIGNUM **u) {
    char *catString_u = malloc(strlen(usr->Astr)+1 + strlen(Bstr)+1);
    strcpy(catString_u, usr->Astr);
    strcat(catString_u, Bstr);
    
    unsigned char lbuff[SHA256_DIGEST_LENGTH] = "";
    hash(usr->hash_alg, (const unsigned char *)catString_u, strlen(catString_u), lbuff);
    *u = BN_bin2bn(lbuff, hash_length(usr->hash_alg), NULL);
    
    free(catString_u);
}

void meteor_user_generate_x(SRPUser *usr,
                            char const *identity,
                            char const *salt,
                            char const *password,
                            unsigned char *buff,
                            BIGNUM **x) {
    const static char *static_delim = ":";
    BIGNUM *x_inner;

    char *catString_i_p = malloc(strlen(identity)+1 + strlen(static_delim)+ 1 + strlen(password)+1 + 1);
    strcpy(catString_i_p, identity);
    strcat(catString_i_p, static_delim);
    strcat(catString_i_p, password);
    catString_i_p[strlen(catString_i_p)] = '\0';
    
    unsigned char lbuff[SHA256_DIGEST_LENGTH] = "";
    hash(usr->hash_alg, (const unsigned char *)catString_i_p, strlen(catString_i_p), lbuff);
    x_inner = BN_bin2bn(lbuff, hash_length(usr->hash_alg), NULL);

    char *x_inner_str_lower = convert_to_lower(BN_bn2hex(x_inner));

    char *catString_s_i_p = malloc(strlen(salt)+1 + strlen(x_inner_str_lower)+1 + 1);
    strcpy(catString_s_i_p, salt);
    strcat(catString_s_i_p, x_inner_str_lower);
    catString_s_i_p[strlen(catString_s_i_p)] = '\0';

    unsigned char xbuff[SHA256_DIGEST_LENGTH] = "";
    hash(usr->hash_alg, (const unsigned char *)catString_s_i_p, strlen((char *)catString_s_i_p), xbuff);
    *x = BN_bin2bn(xbuff, hash_length(usr->hash_alg), NULL);
    
    BN_free(x_inner);
    free(catString_i_p);
    free(catString_s_i_p);
}

void meteor_user_generate_k( SRPUser *usr,
                             unsigned char *buff,
                             BIGNUM **k ) {
    if (!usr->ng) return;
    char *N_str = BN_bn2hex(usr->ng->N);

    // generator (g) is always 0x02 but bn2hex represents
    // string as 02 and meteor (javascript) lib represents as 2
    // so hard coding this value to 2 to be able to generate
    // what meteor expects
    static const char *g_str = "2";

    char *cat_string_n_g = malloc(strlen(N_str)+1 + strlen(g_str)+1 + 1);
    strcpy(cat_string_n_g, N_str);
    strcat(cat_string_n_g, g_str);
    cat_string_n_g[strlen(cat_string_n_g)] = '\0';
    
    char *ng = convert_to_lower(cat_string_n_g);
    unsigned char lbuff[SHA256_DIGEST_LENGTH] = "";
    hash(usr->hash_alg, (const unsigned char *)ng, strlen(ng), lbuff);

    *k = BN_bin2bn(lbuff, hash_length(usr->hash_alg), NULL);
    free(cat_string_n_g);
}

void meteor_user_generate_kgx(SRPUser *usr,
                              BN_CTX *ctx,
                              BIGNUM *x,
                              BIGNUM *k,
                              BIGNUM **kgx) {
    if (!usr->ng) return;
    BN_CTX *lctx = BN_CTX_new();
    BIGNUM *inner_kgx = BN_new();
    BN_mod_exp(inner_kgx, usr->ng->g, x, usr->ng->N, lctx);
    BN_mul(*kgx, inner_kgx, k, lctx);
    
    BN_free(inner_kgx);
    BN_CTX_free(lctx);
}

void meteor_user_generate_aux(SRPUser *usr,
                              BN_CTX *ctx,
                              BIGNUM *u,
                              BIGNUM *x,
                              BIGNUM **aux) {
    if (!usr->a) return;
    BN_CTX *lctx = BN_CTX_new();
    BIGNUM *ux = BN_new();
    BN_mul(ux, u, x, lctx);
    BN_add(*aux, usr->a, ux);
    
    BN_free(ux);
    BN_CTX_free(lctx);
}

void meteor_user_generate_S_string(SRPUser *usr,
                                   BN_CTX *ctx,
                                   BIGNUM *kgx,
                                   BIGNUM *aux,
                                   const char *B_str,
                                   char **S_str) {
    if (!usr->ng) return;
    
    BN_CTX *lctx = BN_CTX_new();
    BIGNUM *B = BN_new();
    BIGNUM *bkgx = BN_new();
    BIGNUM *S = BN_new();

    BN_hex2bn(&B, B_str);
    BN_sub(bkgx, B, kgx);
    BN_mod_exp(S, bkgx, aux, usr->ng->N, lctx);
    *S_str = convert_to_lower(BN_bn2hex(S));
    usr->Sstr = convert_to_lower(BN_bn2hex(S));
    
    BN_free(B);
    BN_free(bkgx);
    BN_free(S);
    BN_CTX_free(lctx);
}

const char * meteor_user_generate_M_string(SRPUser *usr,
                                   const char *S_str,
                                   unsigned char *buff,
                                   const char *B_str) {
    BIGNUM *M = BN_new();

    char *ABS = malloc(strlen(usr->Astr)+1 + strlen(B_str)+1 + strlen(S_str)+1 + 1);
    strcpy(ABS, usr->Astr);
    strcat(ABS, B_str);
    strcat(ABS, usr->Sstr);
    ABS[strlen(ABS)] = '\0';

    unsigned char lbuff[SHA256_DIGEST_LENGTH] = "";
    hash(usr->hash_alg, (const unsigned char *)ABS, strlen(ABS), lbuff);
    M = BN_bin2bn(lbuff, hash_length(usr->hash_alg), NULL);
    
    free(ABS);
    
    return convert_to_lower(BN_bn2hex(M));
}

void meteor_user_generate_HAMK(SRPUser *usr,
                               unsigned char *buff,
                               const char *M_str,
                               const char *S_str) {
    char *AMS = malloc(strlen(usr->Astr)+1 + strlen(M_str)+1 + strlen(S_str)+1 + 1);
    strcpy(AMS, usr->Astr);
    strcat(AMS, M_str);
    strcat(AMS, S_str);
    AMS[strlen(AMS)] = '\0';
    
    unsigned char lbuff[SHA256_DIGEST_LENGTH] = "";
    hash(usr->hash_alg, (const unsigned char *)AMS, strlen(AMS), lbuff);
    usr->HAMK = BN_bn2hex(BN_bin2bn(lbuff, hash_length(usr->hash_alg), NULL));
    
    free(AMS);
}

void srp_user_process_meteor_challenge(SRPUser *usr,
                                       const char *password,
                                       const char *salt,
                                       const char *identity,
                                       const char *Bstr,
                                       const char **Mstr) {
    unsigned char buff[SHA256_DIGEST_LENGTH];
    BN_CTX *ctx = BN_CTX_new();
    
    BIGNUM *u = BN_new();
    BIGNUM *x = BN_new();
    BIGNUM *k = BN_new();
    BIGNUM *kgx = BN_new();
    BIGNUM *aux = BN_new();
    
    meteor_user_generate_u(usr, Bstr, buff, &u);
    meteor_user_generate_x(usr, identity, salt, password, buff, &x);
    meteor_user_generate_k(usr, buff, &k);
    meteor_user_generate_kgx(usr, ctx, x, k, &kgx);
    meteor_user_generate_aux(usr, ctx, u, x, &aux);
    char *S_str = 0;
    meteor_user_generate_S_string(usr, ctx, kgx, aux, Bstr, &S_str);
    if (S_str) {
        *Mstr = meteor_user_generate_M_string(usr, S_str, buff, Bstr);
        meteor_user_generate_HAMK(usr, buff, *Mstr, S_str);
    }
    
    BN_free(u);
    BN_free(x);
    BN_free(k);
    BN_free(kgx);
    BN_free(aux);
}

void srp_user_verify_meteor_session( SRPUser * usr, const char * HAMK_meteor )
{
    usr->authenticated = strcmp(usr->HAMK, HAMK_meteor) ? 0 : 1;
}

void srp_user_verify_session( SRPUser * usr, const unsigned char * bytes_HAMK )
{
    if ( memcmp( usr->H_AMK, bytes_HAMK, hash_length(usr->hash_alg) ) == 0 )
        usr->authenticated = 1;
}
