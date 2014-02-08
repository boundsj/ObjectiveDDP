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

/* 
 * 
 * Purpose:       This is a direct implementation of the Secure Remote Password
 *                Protocol version 6a as described by 
 *                http://srp.stanford.edu/design.html
 * 
 * Author:        tom.cocagne@gmail.com (Tom Cocagne)
 * 
 * Dependencies:  OpenSSL (and Advapi32.lib on Windows)
 * 
 * Usage:         Refer to test_srp.c for a demonstration
 * 
 * Notes:
 *    This library allows multiple combinations of hashing algorithms and 
 *    prime number constants. For authentication to succeed, the hash and
 *    prime number constants must match between 
 *    srp_create_salted_verification_key(), srp_user_new(),
 *    and srp_verifier_new(). A recommended approach is to determine the
 *    desired level of security for an application and globally define the
 *    hash and prime number constants to the predetermined values.
 * 
 *    As one might suspect, more bits means more security. As one might also
 *    suspect, more bits also means more processing time. The test_srp.c 
 *    program can be easily modified to profile various combinations of 
 *    hash & prime number pairings.
 */

#ifndef SRP_H
#define SRP_H

#include <bn.h>
#include <sha.h>

struct SRPVerifier;

typedef enum
{
    SRP_NG_1024,
    SRP_NG_2048,
    SRP_NG_4096,
    SRP_NG_8192,
    SRP_NG_CUSTOM
} SRP_NGType;

typedef enum 
{
    SRP_SHA1, 
    SRP_SHA224, 
    SRP_SHA256,
    SRP_SHA384, 
    SRP_SHA512
} SRP_HashAlgorithm;

/* This library will automatically seed the OpenSSL random number generator
 * using cryptographically sound random data on Windows & Linux. If this is
 * undesirable behavior or the host OS does not provide a /dev/urandom file, 
 * this function may be called to seed the random number generator with 
 * alternate data.
 *
 * The random data should include at least as many bits of entropy as the
 * largest hash function used by the application. So, for example, if a
 * 512-bit hash function is used, the random data requies at least 512
 * bits of entropy.
 * 
 * Passing a null pointer to this function will cause this library to skip
 * seeding the random number generator. This is only legitimate if it is
 * absolutely known that the OpenSSL random number generator has already
 * been sufficiently seeded within the running application.
 * 
 * Notes: 
 *    * This function is optional on Windows & Linux and mandatory on all
 *      other platforms.
 */
void srp_random_seed( const unsigned char * random_data, int data_length );

typedef struct
{
    BIGNUM     * N;
    BIGNUM     * g;
} NGConstant;

typedef struct
{
    SRP_HashAlgorithm  hash_alg;
    NGConstant        *ng;
    
    BIGNUM *a;
    BIGNUM *A;
    BIGNUM *S;
    
    const char *HAMK;
    const unsigned char *bytes_A;
    const char *Astr;
    const char *Sstr;
    int authenticated;
    
    const char *username;
    const char *password;
    int password_len;
    
    unsigned char H_AMK[SHA512_DIGEST_LENGTH];
    unsigned char session_key[SHA512_DIGEST_LENGTH];
} SRPUser;

/* Out: bytes_s, len_s, bytes_v, len_v
 * 
 * The caller is responsible for freeing the memory allocated for bytes_s and bytes_v
 * 
 * The n_hex and g_hex parameters should be 0 unless SRP_NG_CUSTOM is used for ng_type.
 * If provided, they must contain ASCII text of the hexidecimal notation.
 */
void srp_create_salted_verification_key( SRP_HashAlgorithm alg, 
                                         SRP_NGType ng_type, const char * username,
                                         const unsigned char * password, int len_password,
                                         const unsigned char ** bytes_s, int * len_s, 
                                         const unsigned char ** bytes_v, int * len_v,
                                         const char * n_hex, const char * g_hex, _Bool use_given_salt );

/* Out: bytes_B, len_B.
 * 
 * On failure, bytes_B will be set to NULL and len_B will be set to 0
 * 
 * The n_hex and g_hex parameters should be 0 unless SRP_NG_CUSTOM is used for ng_type
 */
struct SRPVerifier *  srp_verifier_new( SRP_HashAlgorithm alg, SRP_NGType ng_type, const char * username,
                                        const unsigned char * bytes_s, int len_s, 
                                        const unsigned char * bytes_v, int len_v,
                                        const unsigned char * bytes_A, int len_A,
                                        const unsigned char ** bytes_B, int * len_B,
                                        const char * n_hex, const char * g_hex );


void                  srp_verifier_delete( struct SRPVerifier * ver );

int                   srp_verifier_is_authenticated( struct SRPVerifier * ver );

const char *          srp_verifier_get_username( struct SRPVerifier * ver );

/* key_length may be null */
const unsigned char * srp_verifier_get_session_key( struct SRPVerifier * ver, int * key_length );

int                   srp_verifier_get_session_key_length( struct SRPVerifier * ver );

/* user_M must be exactly srp_verifier_get_session_key_length() bytes in size */
void                  srp_verifier_verify_session( struct SRPVerifier * ver,
                                                   const unsigned char * user_M, 
                                                   const unsigned char ** bytes_HAMK );

/*******************************************************************************/

/* The n_hex and g_hex parameters should be 0 unless SRP_NG_CUSTOM is used for ng_type */
SRPUser * srp_user_new_with_a(SRP_HashAlgorithm alg,
                              SRP_NGType ng_type,
                              const char * username,
                              const char * password,
                              const char * n_hex,
                              const char * g_hex,
                              BIGNUM *a);

/* The n_hex and g_hex parameters should be 0 unless SRP_NG_CUSTOM is used for ng_type */
SRPUser * srp_user_new(SRP_HashAlgorithm alg,
                       SRP_NGType ng_type,
                       const char *username,
                       const char *password,
                       const char * n_hex,
                       const char * g_hex);
                                    
void                  srp_user_delete( SRPUser * usr );

int                   srp_user_is_authenticated( SRPUser * usr);

const char *          srp_user_get_username( SRPUser * usr );

/* key_length may be null */
const unsigned char * srp_user_get_session_key( SRPUser * usr, int * key_length );

int                   srp_user_get_session_key_length( SRPUser * usr );

/* Output: username, bytes_A, len_A, Astr */
const char * srp_user_start_authentication(SRPUser *usr);

/* Output: bytes_M, len_M  (len_M may be null and will always be
 *                          srp_user_get_session_key_length() bytes in size) */
void                  srp_user_process_challenge( SRPUser * usr, 
                                                  const unsigned char * bytes_s, int len_s, 
                                                  const unsigned char * bytes_B, int len_B,
                                                  const unsigned char ** bytes_M, int * len_M );
                                                  
/* bytes_HAMK must be exactly srp_user_get_session_key_length() bytes in size */
void                  srp_user_verify_session( SRPUser * usr, const unsigned char * bytes_HAMK );

void srp_user_process_meteor_challenge(SRPUser *usr,
                                       const char *password,
                                       const char *salt,
                                       const char *identity,
                                       const char *Bstr,
                                       const char **Mstr);

void srp_user_verify_meteor_session( SRPUser * usr, const char * HAMK_meteor );

#endif /* Include Guard */
